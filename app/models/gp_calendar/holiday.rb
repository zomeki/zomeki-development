# encoding: utf-8
class GpCalendar::Holiday < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Rel::Unid
  include Sys::Model::Rel::Creator
  include Sys::Model::Rel::File
  include Cms::Model::Auth::Content

  STATE_OPTIONS = [['公開', 'public'], ['非公開', 'closed']]
  KIND_OPTIONS = [['休日', 'holiday'], ['イベント', 'event']]
  ORDER_OPTIONS = [['作成日時（降順）', 'created_at_desc'], ['作成日時（昇順）', 'created_at_asc']]

  # Content
  belongs_to :content, :foreign_key => :content_id, :class_name => 'GpCalendar::Content::Event'
  validates_presence_of :content_id

  # Proper
  belongs_to :status, :foreign_key => :state, :class_name => 'Sys::Base::Status'
  validates_presence_of :state

  after_initialize :set_defaults

  validates_presence_of :title

  scope :public, where(state: 'public')

  def self.all_with_content_and_criteria(content, criteria)
    holidays = self.arel_table

    rel = self.where(holidays[:content_id].eq(content.id))
    rel = rel.where(holidays[:title].matches("%#{criteria[:title]}%")) if criteria[:title].present?
    fdt = Arel::Nodes::NamedFunction.new("date_format", [holidays[:date], "%m%d"])
    rel = rel.where(fdt.eq(criteria[:date].strftime('%m%d'))) if criteria[:date].present?
    rel = case criteria[:order]
          when 'created_at_desc'
            rel.except(:order).order(holidays[:created_at].desc)
          when 'created_at_asc'
            rel.except(:order).order(holidays[:created_at].asc)
          else
            rel
          end

    if /^\d{6}$/ =~ (month = criteria[:month])
      begin
        start_date = Date.new(month.slice(0, 4).to_i, month.slice(4, 2).to_i, 1)
        end_date = start_date.end_of_month
        fdt = Arel::Nodes::NamedFunction.new("date_format", [holidays[:date], "%m"])
        rel = rel.where(fdt.eq(start_date.strftime('%m')))
      rescue ArgumentError => e
        warn_log("#{self} #{e.message}")
      end
    end

    return rel
  end

  belongs_to :doc, :class_name => 'GpArticle::Doc' # Not saved to database

  def started_on=(year)
    @started_on = Date.new(year, self.date.month, self.date.day) if self.date.present?
  end

  def started_on
logger.info @started_on
    @started_on
  end

  def ended_on
    self.started_on
  end

  attr_accessor :href, :name, :categories  # Similarly to event

  private

  def set_defaults
    self.state ||= STATE_OPTIONS.first.last if self.has_attribute?(:state)
  end

end
