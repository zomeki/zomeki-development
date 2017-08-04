# encoding: utf-8
class GpCategory::Public::Node::CategoriesController < GpCategory::Public::Node::BaseController
  include Rank::Controller::Rank

  def show
    category_type = @content.category_types.find_by_name(params[:category_type_name])
    @category = category_type.find_category_by_path_from_root_category(params[:category_names])
    return http_error(404) unless @category.try(:public?)

    if params[:format].in?('rss', 'atom')
      docs = @category.public_docs.order('display_published_at DESC, published_at DESC')
      docs = docs.display_published_after(@content.feed_docs_period.to_i.days.ago) if @content.feed_docs_period.present?
      docs = docs.paginate(page: params[:page], per_page: @content.feed_docs_number)
      return render_feed(docs)
    end

    Page.current_item = @category
    Page.title = @category.title

    per_page = (@more ? 30 : @content.category_docs_number)

    if (template = @category.inherited_template)
      if @more
        @docs = case
                when 'l1'.in?(@more_options)
                  find_public_docs_with_category_id(@category.id)
                else
                  find_public_docs_with_category_id(@category.public_descendants.map(&:id))
                end

        feature = case
                  when 'f1'.in?(@more_options)
                    'feature_1'
                  when 'f2'.in?(@more_options)
                    'feature_2'
                  else
                    ''
                  end
        @docs = @docs.where(feature, true) if @docs.columns.any?{|c| c.name == feature }

        filter = @more_options.detect{|o| o =~ /^(c|g)_/i }
        if filter
          prefix, code_or_name = filter.split('_', 2)

          case prefix
          when 'c'
            return http_error(404) unless category_type.internal_category_type

            internal_category = category_type.internal_category_type.public_root_categories.find_by_name(code_or_name)
            return http_error(404) unless internal_category

            categorizations = GpCategory::Categorization.where(categorizable_type: 'GpArticle::Doc', categorized_as: 'GpArticle::Doc',
                                                               categorizable_id: @docs.pluck(:id),
                                                               category_id: internal_category.public_descendants.map(&:id))
            @docs = GpArticle::Doc.where(id: categorizations.pluck(:categorizable_id))
          when 'g'
            @docs = @docs.joins(:creator => :group).where(Sys::Group.arel_table[:code].eq(code_or_name))
          end
        end

        @docs = case @content.docs_order
          when 'published_at_desc'
            @docs.order('display_published_at DESC, published_at DESC')
          when 'published_at_asc'
            @docs.order('display_published_at ASC, published_at ASC')
          when 'updated_at_desc'
            @docs.order('display_updated_at DESC, updated_at DESC')
          when 'updated_at_asc'
            @docs.order('display_updated_at ASC, updated_at ASC')
          else
            @docs.order('display_published_at DESC, published_at DESC')
          end
    
        @docs = @docs.paginate(page: params[:page], per_page: per_page)
        return http_error(404) if @docs.current_page > @docs.total_pages
        render :more
      else
        return http_error(404) if params[:page]

        vc = view_context
        rendered = template.body.gsub(/\[\[module\/([\w-]+)\]\]/) do |matched|
            tm = @content.template_modules.find_by_name($1)
            next unless tm

            case tm.module_type
            when 'categories_1', 'categories_2', 'categories_3'
              if vc.respond_to?(tm.module_type)
                @category.public_children.inject(''){|tags, child|
                  tags << vc.content_tag(:section, class: child.name) do
                      html = vc.content_tag(:h2, vc.link_to(child.title, child.public_uri))
                      html << vc.send(tm.module_type, template_module: tm,
                                      categories: child.public_children)
                    end
                }
              end
            when 'docs_1', 'docs_2'
              if vc.respond_to?(tm.module_type)
                docs = case tm.module_type
                       when 'docs_1'
                         find_public_docs_with_category_id(@category.public_descendants.map(&:id))
                       when 'docs_2'
                         find_public_docs_with_category_id(@category.id)
                       end
                docs = docs.where(tm.module_type_feature, true) if docs.columns.any?{|c| c.name == tm.module_type_feature }

                all_docs = case @content.docs_order
                  when 'published_at_desc'
                    docs.order('display_published_at DESC, published_at DESC')
                  when 'published_at_asc'
                    docs.order('display_published_at ASC, published_at ASC')
                  when 'updated_at_desc'
                    docs.order('display_updated_at DESC, updated_at DESC')
                  when 'updated_at_asc'
                    docs.order('display_updated_at ASC, updated_at ASC')
                  else
                    docs.order('display_published_at DESC, published_at DESC')
                  end
            
                docs = all_docs.limit(tm.num_docs)
                vc.send(tm.module_type, template_module: tm,
                        ct_or_c: @category, docs: docs, all_docs: all_docs)
              end
            when 'docs_3', 'docs_4'
              if vc.respond_to?(tm.module_type) && category_type.internal_category_type
                docs = case tm.module_type
                       when 'docs_3'
                         find_public_docs_with_category_id(@category.public_descendants.map(&:id))
                       when 'docs_4'
                         find_public_docs_with_category_id(@category.id)
                       end
                docs = docs.where(tm.module_type_feature, true) if docs.columns.any?{|c| c.name == tm.module_type_feature }

                categorizations = GpCategory::Categorization.where(categorizable_type: 'GpArticle::Doc', categorizable_id: docs.pluck(:id), categorized_as: 'GpArticle::Doc')
                vc.send(tm.module_type, template_module: tm,
                        ct_or_c: @category,
                        categories: category_type.internal_category_type.public_root_categories, categorizations: categorizations)
              end
            when 'docs_5', 'docs_6'
              if vc.respond_to?(tm.module_type)
                docs = case tm.module_type
                       when 'docs_5'
                         find_public_docs_with_category_id(@category.public_descendants.map(&:id))
                       when 'docs_6'
                         find_public_docs_with_category_id(@category.id)
                       end
                docs = docs.where(tm.module_type_feature, true) if docs.columns.any?{|c| c.name == tm.module_type_feature }

                docs = docs.joins(:creator => :group)
                groups = Sys::Group.where(id: docs.pluck(Sys::Group.arel_table[:id]).uniq)
                vc.send(tm.module_type, template_module: tm,
                        ct_or_c: @category,
                        groups: groups, docs: docs)
              end
            when 'docs_7', 'docs_8'
              if view_context.respond_to?(tm.module_type)
                docs = find_public_docs_with_category_id(@category.public_descendants.map(&:id))
                docs = docs.where(tm.module_type_feature, true) if docs.columns.any?{|c| c.name == tm.module_type_feature }

                categorizations = GpCategory::Categorization.where(categorizable_type: 'GpArticle::Doc', categorizable_id: docs.pluck(:id), categorized_as: 'GpArticle::Doc')
                vc.send(tm.module_type, template_module: tm,
                        categories: @category.children, categorizations: categorizations)
              end
            else
              ''
            end
          end

        render text: vc.content_tag(:div, rendered.html_safe, class: 'contentGpCategory contentGpCategoryCategory')
      end
    else
      @docs = @category.public_docs.order('display_published_at DESC, published_at DESC').paginate(page: params[:page], per_page: per_page)
      return http_error(404) if @docs.current_page > @docs.total_pages

      if Page.mobile?
        render :show_mobile
      else
        if @more
          render 'more'
        else
          if (style = @content.category_style).present?
            render style
          end
        end
      end
    end
  end
  
  def rank
    return http_error(404) unless @content.rank_related?
    return http_error(404) unless @rank_content = @content.rank_content_rank
    
    category_type = @content.category_types.find_by_name(params[:category_type_name])
    @category = category_type.find_category_by_path_from_root_category(params[:category_names])
    return http_error(404) unless @category.try(:public?)

    Page.current_item = @category
    Page.title = @category.title

    case @content.ranking_term
    when 'previous_days'
      @term   = 'previous_days'
      @target = 'pageviews'
    when 'last_weeks'
      @term   = 'last_weeks'
      @target = 'pageviews'
    when 'last_months'
      @term   = 'last_months'
      @target = 'pageviews'
    when 'this_weeks'
      @term   = 'this_weeks'
      @target = 'pageviews'
    end
    
    @node_uri = Page.current_node.public_uri
    options = {:page_path => @node_uri,
              :exclusion_url => [@node_uri, "#{@node_uri}rank.html"]}
    @ranks  = rank_datas(@rank_content, @term, @target, @content.ranking_display_count,
                          'on', nil, nil, nil, nil, options)
  end
end
