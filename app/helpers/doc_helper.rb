# encoding: utf-8
module DocHelper
  def doc_replace(doc, doc_style, date_style)

    link_to_options = link_to_doc_options(doc)

    doc_title = if link_to_options
                  link_to *([doc.title] + link_to_options)
                else
                  h doc.title
                end

    image_file = doc.image_files.detect{|f| f.name == doc.list_image } || doc.image_files.first if doc.list_image.present?

    doc_image = if image_file
                  if link_to_options
                    link_to *([image_tag("#{doc.content.public_node.public_uri}#{doc.name}/file_contents/#{url_encode image_file.name}")] + link_to_options)
                  else
                    image_tag("#{doc.content.public_node.public_uri}#{doc.name}/file_contents/#{url_encode image_file.name}")
                  end
                else
                  unless (img_tags = Nokogiri::HTML.parse(doc.body).css('img[src^="file_contents/"]')).empty?
                    filename = File.basename(img_tags.first.attributes['src'].value)
                    if link_to_options
                      link_to *([image_tag("#{doc.content.public_node.public_uri}#{doc.name}/file_contents/#{url_encode filename}")] + link_to_options)
                    else
                      image_tag("#{doc.content.public_node.public_uri}#{doc.name}/file_contents/#{url_encode filename}")
                    end
                  else
                    ''
                  end
                end

    contents = {
      title: doc_title.blank? ? '' : content_tag(:span, doc_title, class: 'title'),
      subtitle: doc.subtitle.blank? ? '' : content_tag(:span, doc.subtitle, class: 'subtitle'),
      publish_date: doc.display_published_at.blank? ? '' : content_tag(:span, doc.display_published_at.try(:strftime, date_style), class: 'publish_date'),
      update_date: doc.display_updated_at.blank? ? '' : content_tag(:span, doc.display_updated_at.try(:strftime, date_style), class: 'update_date'),
      summary: doc.summary.blank? ? '' : content_tag(:span, doc.summary, class: 'summary'),
      group: doc.creator.blank? ? '' : content_tag(:span, doc.creator.group.name, class: 'group'),
      category_link: doc.categories.blank? ? '' : content_tag(:span, doc.categories.map{|c| link_to c.title, c.public_uri }.join(', ').html_safe, class: 'category'),
      category: doc.categories.blank? ? '' : content_tag(:span, doc.categories.pluck(:title).join(', '), class: 'category'),
      image: doc_image.blank? ? '' : content_tag(:span, doc_image, class: 'image'),
      }

    return doc_style.gsub(/@title@?/, contents[:title])
               .gsub(/@subtitle@?/, contents[:subtitle])
               .gsub(/@publish_date@?/, contents[:publish_date])
               .gsub(/@update_date@?/, contents[:update_date])
               .gsub(/@summary@?/, contents[:summary])
               .gsub(/@group@?/, contents[:group])
               .gsub(/@category_link@?/, contents[:category_link])
               .gsub(/@category@?/, contents[:category])
               .gsub(/@image@?/, contents[:image]).html_safe
  end
end
