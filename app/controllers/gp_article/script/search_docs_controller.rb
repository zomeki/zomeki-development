class GpArticle::Script::ArchivesController < Cms::Controller::Script::Publication
  def publish
    info_log 'GpArticle::Script::ArchivesController#publish'
    render text: 'OK'
  rescue => e
    error_log e.message
    render text: e.message
  end
end
