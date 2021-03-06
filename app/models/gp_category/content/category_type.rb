# encoding: utf-8
class GpCategory::Content::CategoryType < Cms::Content
  CATEGORY_TYPE_STYLE_OPTIONS = [['全カテゴリ一覧', 'all_categories'], ['全記事一覧', 'all_docs'], ['カテゴリ＋記事', 'categories_with_docs']]
  CATEGORY_STYLE_OPTIONS = [['カテゴリ一覧＋記事一覧', 'categories_and_docs'], ['カテゴリ＋記事', 'categories_with_docs']]
  DOC_STYLE_OPTIONS = [['全記事一覧', 'all_docs']]
  DOCS_ORDER_OPTIONS = [['公開日（降順）', 'published_at_desc'], ['公開日（昇順）', 'published_at_asc'], 
                        ['更新日（降順）', 'updated_at_desc'], ['更新日（昇順）', 'updated_at_asc']]
  FEED_DISPLAY_OPTIONS = [['表示する', 'enabled'], ['表示しない', 'disabled']]
  RANK_RELATION_OPTIONS = [['使用する', 'enabled'], ['使用しない', 'disabled']]
  RANKING_TERMS_OPTIONS = [['前日', 'previous_days'], ['先週（月曜日〜日曜日）', 'last_weeks'], ['先月', 'last_months'], ['週間（前日から二週間）', 'this_weeks']]

  default_scope { where(model: 'GpCategory::CategoryType') }

  has_many :category_types, :foreign_key => :content_id, :class_name => 'GpCategory::CategoryType', :order => "#{GpCategory::CategoryType.table_name}.sort_no", :dependent => :destroy
  has_many :templates, :foreign_key => :content_id, :class_name => 'GpCategory::Template', :dependent => :destroy
  has_many :template_modules, :foreign_key => :content_id, :class_name => 'GpCategory::TemplateModule', :dependent => :destroy

  before_create :set_default_settings

  def public_nodes
    nodes.public
  end

  def public_node
    public_nodes.order(:id).first
  end

#TODO: DEPRECATED
  def category_type_node
    return @category_type_node if @category_type_node
    @category_type_node = Cms::Node.where(state: 'public', content_id: id, model: 'GpCategory::CategoryType').order(:id).first
  end

  def public_category_types
    category_types.public
  end

  def category_types_for_option
    category_types.map {|ct| [ct.title, ct.id] }
  end

  def group_category_type_name
    setting_value(:group_category_type_name).presence || 'groups'
  end

  def group_category_type
    category_types.find_by_name(group_category_type_name)
  end

  def list_style
    setting_value(:list_style).to_s
  end

  def date_style
    setting_value(:date_style).to_s
  end

  def time_style
    setting_value(:time_style).to_s
  end

  def category_type_style
    setting_value(:category_type_style).to_s
  end

  def category_type_doc_style
    setting_extra_value(:category_type_style, :category_type_doc_style).to_s
  end

  def category_type_docs_number
    (setting_extra_value(:category_type_style, :category_type_docs_number).presence || 1000).to_i
  end

  def category_style
    setting_value(:category_style).to_s
  end

  def category_doc_style
    setting_extra_value(:category_style, :category_doc_style).to_s
  end

  def category_docs_number
    (setting_extra_value(:category_style, :category_docs_number).presence || 1000).to_i
  end

  def doc_style
    setting_value(:doc_style).to_s
  end

  def doc_doc_style
    setting_extra_value(:doc_style, :doc_doc_style).to_s
  end

  def doc_docs_number
    (setting_extra_value(:doc_style, :doc_docs_number).presence || 1000).to_i
  end

  def docs_order
    setting_value(:docs_order).to_s
  end

  def rank_related?
    setting_value(:rank_relation) == 'enabled'
  end

  def rank_content_rank
    Rank::Content::Rank.find_by_id(setting_extra_value(:rank_relation, :rank_content_id))
  end
  
  def ranking_term
    setting_extra_value(:rank_relation, :ranking_term).to_s
  end

  def ranking_display_count
    (setting_extra_value(:rank_relation, :ranking_display_count).presence || 50).to_i
  end  

  def feed_display?
    setting_value(:feed) != 'disabled'
  end

  def feed_docs_number
    (setting_extra_value(:feed, :feed_docs_number).presence || 10).to_i
  end

  def feed_docs_period
    setting_extra_value(:feed, :feed_docs_period)
  end

  def index_template
    templates.find_by_id(setting_value(:index_template_id))
  end

  private

  def set_default_settings
    in_settings[:list_style] = '@title_link@(@publish_date@ @group@)' unless setting_value(:list_style)
    in_settings[:date_style] = '%Y年%m月%d日 %H時%M分' unless setting_value(:date_style)
    in_settings[:time_style] = '%H時%M分' unless setting_value(:time_style)
    in_settings[:docs_order] = DOCS_ORDER_OPTIONS.first.last unless setting_value(:docs_order)
    in_settings[:rank_relation] = RANK_RELATION_OPTIONS.first.last unless setting_value(:rank_relation)
    in_settings[:feed] = 'enabled' unless setting_value(:feed)
  end
end
