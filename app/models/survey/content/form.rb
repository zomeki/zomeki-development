# encoding: utf-8
class Survey::Content::Form < Cms::Content
  APPROVAL_RELATION_OPTIONS = [['使用する', 'enabled'], ['使用しない', 'disabled']]
  CAPTCHA_OPTIONS = [['使用する', 'enabled'], ['使用しない', 'disabled']]

  default_scope where(model: 'Survey::Form')

  has_many :forms, :foreign_key => :content_id, :class_name => 'Survey::Form', :dependent => :destroy

  before_create :set_default_settings

  def public_forms
    forms.public
  end

  def public_nodes
    nodes.public
  end

  def public_node
    public_nodes.first
  end

  def mail_from
    setting_value(:mail_from).to_s
  end

  def mail_to
    setting_value(:mail_to).to_s
  end

  def approval_content_approval_flow
    Approval::Content::ApprovalFlow.find_by_id(setting_extra_value(:approval_relation, :approval_content_id))
  end

  def approval_related?
    setting_value('approval_relation') == 'enabled'
  end

  def use_captcha?
    setting_value('captcha') == 'enabled'
  end

  private

  def set_default_settings
    in_settings[:approval_relation] = APPROVAL_RELATION_OPTIONS.first.last if setting_value(:approval_relation).nil?
  end
end
