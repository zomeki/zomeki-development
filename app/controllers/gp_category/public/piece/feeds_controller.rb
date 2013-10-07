# encoding: utf-8
class GpCategory::Public::Piece::FeedsController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = GpCategory::Piece::Feed.find_by_id(Page.current_piece.id)
    render :text => '' unless @piece
    
    @item = Page.current_item
  end
  
  def index
    case @item
    when Cms::Node
      @path = "index" if @item.model == 'GpCategory::Doc'
    when GpCategory::Category
      @path = "show" 
    end
  end
end
