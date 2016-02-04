class GpArticle::Public::Node::SearchDocsController < Cms::Controller::Public::Base
  def pre_dispatch
    @content = GpArticle::Content::Doc.find_by_id(Page.current_node.content.id)
    return http_error(404) unless @content
  end

  def index
    
    @s_keyword = params[:s_keyword]
    if @s_keyword.blank?
      @docs = []
    else
      @docs = public_or_preview_docs
      docs = @docs.arel_table
      @docs = @docs.where(docs[:title].matches("%#{@s_keyword}%")
                      .or(docs[:body].matches("%#{@s_keyword}%")))
      @docs = @docs.order('display_published_at DESC, published_at DESC')

      @docs = @docs.includes(:next_edition).reject{|d| d.will_be_replaced? } unless Core.publish

      @docs = @docs.paginate(page: params[:page], per_page: 20)
      return http_error(404) if @docs.current_page > @docs.total_pages
    end

    render :index_mobile if Page.mobile?
  end

  private

  def public_or_preview_docs(id: nil, name: nil)
    unless Core.mode == 'preview'
      docs = @content.public_docs
      name ? docs.find_by_name(name) : docs
    else
      if Core.publish
        @content.public_docs
      else
        @content.public_docs
      end
    end
  end

  
end
