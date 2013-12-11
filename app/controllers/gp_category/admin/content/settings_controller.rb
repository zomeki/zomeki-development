# encoding: utf-8
class GpCategory::Admin::Content::SettingsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:designer)
    return error_auth unless @content = GpCategory::Content::CategoryType.find(params[:content])
    return error_auth unless @content.editable?
  end

  def index
    @items = GpCategory::Content::Setting.configs(@content)
    _index @items
  end

  def show
    @item = GpCategory::Content::Setting.config(@content, params[:id])
    _show @item
  end

  def edit
    @item = GpCategory::Content::Setting.config(@content, params[:id])
  end

  def update
    @item = GpCategory::Content::Setting.config(@content, params[:id])
    @item.value = params[:item][:value]

    if ['category_type_style', 'category_style', 'doc_style', 'feed'].include?(@item.name)
      extra_values = @item.extra_values

      case @item.name
      when 'category_type_style'
        extra_values[:category_type_doc_style] = params[:category_type_doc_style]
        extra_values[:category_type_docs_number] = params[:category_type_docs_number]
      when 'category_style'
        extra_values[:category_doc_style] = params[:category_doc_style]
        extra_values[:category_docs_number] = params[:category_docs_number]
      when 'doc_style'
        extra_values[:doc_doc_style] = params[:doc_doc_style]
        extra_values[:doc_docs_number] = params[:doc_docs_number]
      when 'feed'
        extra_values[:feed_docs_number] = params[:feed_docs_number]
        extra_values[:feed_docs_period] = params[:feed_docs_period]
      end

      @item.extra_values = extra_values
    end

    _update @item
  end

  def copy_groups
    category_type = @content.category_types.find_by_name(@content.group_category_type_name) || @content.category_types.create(name: @content.group_category_type_name, title: '組織')
    category_type.copy_from_groups(Sys::Group.where(parent_id: 1, level_no: 2))
    redirect_to gp_category_content_settings_path, :notice => 'コピーが完了しました。'
  end
end
