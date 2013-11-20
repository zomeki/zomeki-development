# encoding: utf-8
class Survey::Public::Node::FormsController < Cms::Controller::Public::Base
  include SimpleCaptcha::ControllerHelpers
  before_filter :set_form, only: [:show, :confirm_answers, :send_answers, :finish]
  skip_filter :render_public_layout
  after_filter :call_render_public_layout

  def pre_dispatch
    @node = Page.current_node
    @content = Survey::Content::Form.find_by_id(@node.content.id)
    return http_error(404) unless @content
  end

  def index
    @forms = @content.public_forms
  end

  def show
    @form_answer = @form.form_answers.build(answered_url: "#{@content.site.full_uri.sub(/\/+$/, '')}#{@content.public_node.public_uri}#{@form.name}",
                                            answered_url_title: @form.title,
                                            remote_addr: request.remote_addr, user_agent: request.user_agent)
  end

  def confirm_answers
    build_answer

    if @form_answer.form.confirmation?
      return render(action: 'show') unless @content.use_captcha? ? @form_answer.valid_with_captcha? : @form_answer.valid?
    else
      return render(action: 'show') unless @content.use_captcha? ? @form_answer.save_with_captcha : @form_answer.save
      send_mail_and_redirect_to_finish
    end
  end

  def send_answers
    build_answer

    return render(action: 'show') if params[:edit_answers]
    return render(action: 'show') unless @form_answer.save

    send_mail_and_redirect_to_finish
  end

  def finish
  end

  private

  def set_form
    forms = Core.mode == 'preview' ? @content.forms : @content.public_forms
    @form = forms.find_by_name(params[:id])
    return http_error(404) unless @form
    return render(text: '') unless @form.open?

    Page.current_item = @form
    Page.title = @form.title
  end

  def call_render_public_layout
    render_public_layout unless params[:piece]
  end

  def build_answer
    @form_answer = @form.form_answers.build(answered_url: params[:current_url].try(:sub, %r!/confirm_answers$!, ''),
                                            answered_url_title: params[:current_url_title],
                                            remote_addr: request.remote_addr, user_agent: request.user_agent,
                                            captcha: params[:captcha], captcha_key: params[:captcha_key])
    @form_answer.question_answers = params[:question_answers]
  end

  def send_mail_and_redirect_to_finish
    CommonMailer.survey_receipt(form_answer: @form_answer, from: @content.mail_from, to: @content.mail_to)
                .deliver if @content.mail_from.present? && @content.mail_to.present?

    redirect_to "#{@node.public_uri}#{@form_answer.form.name}/finish#{'?piece=true' if params[:piece]}"
  end
end
