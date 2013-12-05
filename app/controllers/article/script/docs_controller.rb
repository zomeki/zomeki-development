# encoding: utf-8
class Article::Script::DocsController < Cms::Controller::Script::Publication
  include Sys::Controller::CacheSweeper::Base
  include Article::Controller::CacheSweeper

  def publish
    uri  = "#{@node.public_uri}"
    path = "#{@node.public_path}"
    publish_more(@node, :uri => uri, :path => path, :first => 2)
    return render(:text => "OK")
  end

  def publish_by_task
    # reserve_sweeper

    begin
      item = params[:item]
      if item.state == 'recognized'
        puts "-- Publish: #{item.class}##{item.id}"
        uri  = "#{item.public_uri}?doc_id=#{item.id}"
        path = "#{item.public_path}"

        before_update_for_sweeper item

        if !item.publish(render_public_as_string(uri, :site => item.content.site))
          raise item.errors.full_messages
        end
        if item.published? || !::File.exist?("#{path}.r")
          item.publish_page(render_public_as_string("#{uri}index.html.r", :site => item.content.site),
            :path => "#{path}.r", :dependent => :ruby)
        end

        puts "OK: Published"
        params[:task].destroy

        sweep_cache_for_update item
      end
    rescue => e
      puts "Error: #{e}"
    end
    return render(:text => "OK")
  end

  def close_by_task
    #reserve_sweeper

    begin
      item = params[:item]
      if item.state == 'public'
        puts "-- Close: #{item.class}##{item.id}"
        before_update_for_sweeper item

        item.close

        puts "OK: Closed"
        params[:task].destroy

        sweep_cache_for_update item
      end
    rescue => e
      puts "Error: #{e}"
    end
    return render(:text => "OK")
  end
end
