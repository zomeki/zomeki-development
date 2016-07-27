# encoding: utf-8
class Rank::Content::Rank < Cms::Content
  default_scope where(model: 'Rank::Rank')

  has_many :pieces, foreign_key: :content_id, class_name: 'Rank::Piece::Rank', dependent: :destroy
  has_many :ranks, foreign_key: :content_id, class_name: 'Rank::Total', dependent: :destroy

  before_create :set_default_settings

  def self.ranking_terms
    return [['すべて', 'all']] + Rank::Rank::TERMS
  end
  
  def self.default_ranking_terms
    Rank::Content::Rank.ranking_terms.map {|t| t[1]}
  end

  def public_nodes
    nodes.public
  end

  def public_node
    public_nodes.order(:id).first
  end

  #TODO: DEPRECATED
  def rank_node
    return @rank_node if @rank_node
    @rank_node = Cms::Node.where(state: 'public', content_id: id, model: 'Rank::Rank').order(:id).first
  end
  
  def use_ranking_terms
    return @use_ranking_terms if @use_ranking_terms
    @use_ranking_terms = YAML.load(setting_value(:ranking_terms)) if setting_value(:ranking_terms)
    if @use_ranking_terms.blank?
      @use_ranking_terms = Rank::Content::Rank.default_ranking_terms
    end
    @use_ranking_terms
  end

  def access_token
    credentials = GoogleOauth2Installed.credentials
    credentials[:oauth2_client_id] = setting_extra_value(:google_oauth, :client_id)
    credentials[:oauth2_client_secret] = setting_extra_value(:google_oauth, :client_secret)
    credentials[:oauth2_scope] = 'https://www.googleapis.com/auth/analytics.readonly'
    credentials[:oauth2_token] = setting_extra_value(:google_oauth, :oauth2_token)
    GoogleOauth2Installed::AccessToken.new(credentials).access_token
  end

  private

  def set_default_settings
    in_settings[:ranking_terms] = ['previous_days'] unless setting_value(:ranking_terms)
  end

end
