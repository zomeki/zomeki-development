# encoding: utf-8
class Cms::SiteSetting::EmergencyLayout < Cms::SiteSetting
  belongs_to :layout, :foreign_key => :value, :class_name => 'Cms::Layout'

  validates_presence_of :value
  validates_uniqueness_of :value, :scope => :name

  def current_site
    Cms::SiteSetting::EmergencyLayout.where(site_id: Core.site.id)
  end
end
