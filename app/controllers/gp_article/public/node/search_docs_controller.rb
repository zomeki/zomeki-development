require 'will_paginate/array'

class GpArticle::Public::Node::SearchDocsController < Cms::Controller::Public::Base
  def pre_dispatch
    @content = GpArticle::Content::Doc.find_by_id(Page.current_node.content.id)
    return http_error(404) unless @content
  end

  def index
    
    @s_keyword = params[:s_keyword].gsub(/^[[:blank:]]+|[[:blank:]]+$/, '')
    if @s_keyword.blank?
      @docs = []
    else
      @docs = @content.public_docs
      docs = @docs.arel_table
      
      keywords = @s_keyword.split(/[[:blank:]]/)
      
      keywords.each do |key|
        next if key.blank?
        @docs = @docs.where(docs[:title].matches("%#{key}%")
                      .or(docs[:body].matches("%#{key}%")))
      end

      @docs = @docs.order('display_published_at DESC, published_at DESC')

      @docs = @docs.includes(:next_edition).reject{|d| d.will_be_replaced? } unless Core.publish

      @docs = @docs.paginate(page: params[:page], per_page: 20)
      return http_error(404) if @docs.current_page > @docs.total_pages
    end

    render :index_mobile if Page.mobile?
  end

  
end
