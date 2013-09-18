# encoding: utf-8
class GpArticle::Admin::Content::SettingsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:designer)
    return error_auth unless @content = GpArticle::Content::Doc.find(params[:content])
    return error_auth unless @content.editable?
  end

  def index
    @items = GpArticle::Content::Setting.configs(@content)
    _index @items
  end

  def show
    @item = GpArticle::Content::Setting.config(@content, params[:id])
    _show @item
  end

  def edit
    @item = GpArticle::Content::Setting.config(@content, params[:id])
    @item.value = YAML.load(@item.value.presence || '[]') if [:check_boxes, :multiple_select].include?(@item.form_type)
  end

  def update
    @item = GpArticle::Content::Setting.config(@content, params[:id])
    @item.value = params[:item][:value]
    if [:check_boxes, :multiple_select].include?(@item.form_type)
      @item.value = YAML.dump(case @item.value
                              when Hash; @item.value.keys
                              when Array; @item.value
                              else []
                              end)
    end

    if ['gp_category_content_category_type_id', 'calendar_relation', 'map_relation', 'inquiry_setting'].include?(@item.name)
      extra_values = @item.extra_values

      case @item.name
      when 'gp_category_content_category_type_id'
        extra_values[:category_type_ids] = (params[:category_types] || []).map {|ct| ct.to_i }
        extra_values[:visible_category_type_ids] = (params[:visible_category_types] || []).map {|ct| ct.to_i }
        extra_values[:default_category_type_id] = params[:default_category_type].to_i
        extra_values[:default_category_id] = params[:default_category].to_i
      when 'calendar_relation'
        extra_values[:calendar_content_id] = params[:calendar_content_id].to_i
      when 'map_relation'
        extra_values[:map_content_id] = params[:map_content_id].to_i
        extra_values[:lat_lng] = params[:lat_lng]
      when 'inquiry_setting'
        extra_values[:state] = params[:state]
        extra_values[:display_fields] = params[:display_fields] || []
        extra_values[:require_fields] = params[:require_fields] || []
      end

      @item.extra_values = extra_values
    end

    _update(@item) do
      if @item.name == 'calendar_relation' && @content.gp_calendar_content_event.nil?
        @content.docs.where(event_state: 'visible').update_all(event_state: 'hidden')
      end
      if @item.name == 'map_relation' && @content.map_content_marker.nil?
        @content.docs.where(marker_state: 'visible').update_all(marker_state: 'hidden')
      end
    end
  end
end
