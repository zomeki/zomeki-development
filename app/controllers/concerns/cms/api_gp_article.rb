module Cms::ApiGpArticle
  extend ActiveSupport::Concern

  included do
  end

  def gp_article(path:, version:)
    case path.shift
    when 'piece_archives'; gp_article_piece_archives(path: path, version: version)
    when 'piece_docs'; gp_article_piece_docs(path: path, version: version)
    when 'piece_ranks'; gp_article_piece_ranks(path: path, version: version)
    else render_404
    end
  end

  def gp_article_piece_archives(path:, version:)

    piece = GpArticle::Piece::Archive.where(id: params[:piece_id]).first
    return render(json: {}) unless piece && piece.content.public_archives_node

    node = piece.content.public_archives_node

    order = (piece.order == 'desc' ? 'DESC' : 'ASC')
    num_docs = piece.content.public_docs
                              .group("DATE_FORMAT(display_published_at, '%Y-%m')")
                              .order("display_published_at #{order}").count
    num_docs = case piece.term
                when 'year_month'
                  num_docs.inject({}){|result, item|
                    y, m = item[0].split('-')
                    result[y] ||= {}
                    result[y][m] ||= 0
                    result[y][m] += item[1]
                    result
                  }
                when 'year'
                  num_docs.inject({}){|result, item|
                    y, m = item[0].split('-')
                    result[y] ||= 0
                    result[y] += item[1]
                    result
                  }
                else
                  num_docs
                end

    result = {}

    result[:num_docs] = case piece.term
                        when 'year_month'
                          num_docs.map do |key, value|
                                          values = value.map do |k, v|
                                            u = "#{node.public_uri}#{key}/#{k}/"
                                            count = piece.num_docs_visible? ? "(#{v})" : ''
                                            {date: "#{k}月", url: u, count: count}
                                          end
                                          url = "#{node.public_uri}#{key}/"
                                          {date: "#{key}年", url: url, values: values}
                                        end
                        when 'year'
                          num_docs.map do |key, value|
                                          url = "#{node.public_uri}#{key}/"
                                          count = piece.num_docs_visible? ? "(#{value})" : ''
                                          {date: "#{key}年", url: url, count: count}
                                        end
                        else
                          num_docs.map do |key, value| year, month = key.split('-')
                                          url = "#{node.public_uri}#{year}/#{month}/"
                                          count = piece.num_docs_visible? ? "(#{value})" : ''
                                          {date: "#{year}年#{month}月", url: url, count: count}
                                        end
                        end

    render json: result
  end
  
  def gp_article_piece_docs(path:, version:)
    piece = GpArticle::Piece::Doc.where(id: params[:piece_id]).first
    return render(json: {}) unless piece

    result = {}

    docs = piece.content.public_docs.limit(piece.docs_number)
    docs = case piece.docs_order
                    when 'published_at_desc'
                      docs.order('display_published_at DESC, published_at DESC')
                    when 'published_at_asc'
                      docs.order('display_published_at ASC, published_at ASC')
                    when 'updated_at_desc'
                      docs.order('display_updated_at DESC, updated_at DESC')
                    when 'updated_at_asc'
                      docs.order('display_updated_at ASC, updated_at ASC')
                    when 'random'
                      docs.order('RAND()')
                    else
                      docs
                    end
    result[:docs] = docs.map do |doc|
                      ApplicationController.helpers.doc_replace(doc, piece.doc_style, piece.date_style)
                    end
    result[:more] = piece.more_link_body.present? && piece.more_link_url.present? ? {body: piece.more_link_body, url: piece.more_link_url} : {}

    
    render json: result
  end

  def gp_article_piece_ranks(path:, version:)
    return render_404 if path.present?
    return render_405 unless request.get?
    return render_404 unless version == '20150401'

    piece = GpArticle::Piece::Rank.where(id: params[:piece_id]).first
    return render(json: {}) unless piece
    content = GpArticle::Content::Doc.find_by_id(piece.content_id)
    return render(json: {}) unless content
    rank_content = content.rank_content_rank
    return render(json: {}) unless content.rank_related?
    return render(json: {}) unless rank_content = content.rank_content_rank


    begin
      current_item = params[:current_item_class].constantize.find(params[:current_item_id])
    rescue => e
      warn_log "#{__FILE__}:#{__LINE__} #{e.message}"
      return render(json: {})
    end

    term = piece.ranking_term
    target = piece.ranking_target
    term = 'all'
    
    node_uri = content.public_node.public_uri
    options = {:page_path => node_uri,
              :exclusion_url => [node_uri, "#{node_uri}rank.html"]}
    ranks = rank_datas(rank_content, term, target, piece.display_count, nil, nil, nil, nil, nil, options)

    result = {}
    result[:ranks] = ranks.map do |rank|
                         {title: rank.page_title,
                            url: "#{request.scheme}://#{rank.hostname}#{rank.page_path}",
                          count: piece.show_count == 0 ? nil : rank.accesses}
                       end
    result[:more] = if (body = piece.more_link_body).present? && (url = piece.more_link_url).present?
                      {body: body, url: url}
                    end

    render json: result
  end
  
end
