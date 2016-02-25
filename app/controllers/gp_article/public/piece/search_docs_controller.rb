# encoding: utf-8
class GpArticle::Public::Piece::SearchDocsController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = GpArticle::Piece::SearchDoc.find_by_id(Page.current_piece.id)
    return render(text: '') unless @piece

    @node = @piece.content.public_search_docs_node
    return render(text: '') unless @node
  end

  def index
    
    @s_keyword = params[:s_keyword].to_s.gsub(/^[[:blank:]]+|[[:blank:]]+$/, '')
    
  end
end
