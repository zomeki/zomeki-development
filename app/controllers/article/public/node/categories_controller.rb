# encoding: utf-8
class Article::Public::Node::CategoriesController < Cms::Controller::Public::Base
  include Article::Controller::Cache::NodeCategory
  include Article::Controller::Feed

  def pre_dispatch
    return http_error(404) unless @content = Page.current_node.content
    @docs_uri = @content.public_uri('Article::Doc')

    @limit = 50

    if params[:name]
      item = Article::Category.new.public
      item.and :content_id, @content.id
      item.and :name, params[:name]
      return http_error(404) unless @item = item.find(:first)
      Page.current_item = @item
      Page.title        = @item.title
    end
    set_cache_path_info
  end

  def index
    @items = Article::Category.root_items(:content_id => @content.id, :state => 'public')
  end

  def show
    @page  = params[:page]

    return show_feed if params[:file] == "feed"
    return http_error(404) unless params[:file] =~ /^(index|more)$/
    @more  = (params[:file] == 'more')
    @page  = 1  if !@more && !request.mobile?
    @limit = 10 if !@more

    doc = Article::Doc.new.public
    doc.agent_filter(request.mobile)
    doc.and :content_id, @content.id
    request.mobile? ? doc.visible_in_list : doc.visible_in_recent
    doc.category_is @item
    doc.page @page, @limit
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed(@docs)

    return http_error(404) if @more == true && @docs.current_page > @docs.total_pages

    if @item.level_no == 1
      show_group
      return render :action => :show_group
    elsif @item.level_no > 1
      show_detail
      return render :action => :show_detail
    end
    return http_error(404)
  end

  def show_feed #portal
    @feed = true
    @items = []
    return render(:action => :show_group)
  end

  def show_group
    @items = @item.public_children

    @item_docs = Proc.new do |cate|
      doc = Article::Doc.new.public
      doc.agent_filter(request.mobile)
      doc.and :content_id, @content.id
      doc.visible_in_list
      doc.category_is cate
      doc.page @page, @limit
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
  end

  def show_detail
    @items = Article::Unit.find_departments(:web_state => 'public')

    @item_docs = Proc.new do |dep|
      doc = Article::Doc.new.public
      doc.agent_filter(request.mobile)
      doc.and :content_id, Page.current_node.content.id
      doc.visible_in_list
      doc.category_is @item
      doc.unit_is dep
      doc.page @page, @limit
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
  end

  def show_attr
    @page  = params[:page]

    attr = Article::Unit.new.public
    attr.and :name_en, params[:attr]
    return http_error(404) unless @attr = attr.find(:first, :order => :sort_no)

    doc = Article::Doc.new.public
    doc.agent_filter(request.mobile)
    doc.and :content_id, Page.current_node.content.id
    doc.visible_in_list
    doc.category_is @item
    doc.unit_is @attr
    doc.page @page, @limit
    @docs = doc.find(:all, :order => 'published_at DESC')

    return http_error(404) if @docs.current_page > @docs.total_pages
  end
end
