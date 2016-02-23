# encoding: utf-8
class GpArticle::Public::Piece::RanksController < Sys::Controller::Public::Base
  include Rank::Controller::Rank

  def pre_dispatch
    @piece = GpArticle::Piece::Rank.find_by_id(Page.current_piece.id)
    render :text => '' unless @piece
    
    @content = GpArticle::Content::Doc.find_by_id(@piece.content_id)
    render :text => '' unless @content
    
    render :text => '' unless @content.rank_related?
    render :text => '' unless @rank_content = @content.rank_content_rank
  end

  def index
    render :text => '' and return if @piece.ranking_target.blank? || @piece.ranking_term.blank?

    @term   = @piece.ranking_term
    @target = @piece.ranking_target
    
    @term = 'all'

    @node_uri = @content.public_node.public_uri
    options = {:page_path => @node_uri,
              :exclusion_url => [@node_uri, "#{@node_uri}rank.html"]}
    @ranks  = rank_datas(@rank_content, @term, @target, @piece.display_count, nil, nil, nil, nil, nil, options)

    render :text => '' if @ranks.empty?
  end
end
