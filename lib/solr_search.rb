module Muscat
  module Adapters
    module ActiveRecord
      module Base

        MAX_PER_PAGE = 30

        def search_as_ransack(params)
          fields, order, with, page = unpack_params(params)
          per_page = params.has_key?(:per_page) ? params[:per_page] : MAX_PER_PAGE
          search_with_solr(fields, order, with, page, per_page)
        end

        def near_items_as_ransack(params, item)
          prev_item = nil
          next_item = nil
          # page values will be 0 if the prev/next item are on the same result page
          prev_page = 0
          next_page = 0
          fields, order, with, page = unpack_params(params)
          results = search_with_solr(fields, order, with, page)

          position = results.index(item)

          # The current item was not found, we must be coming from somewhere else...
          return prev_item, next_item, prev_page, next_page if position == nil

          # Find the previous and next items
          # It could be condensed in one
          # but it is easyer to read like this

          # Get the prev item in the searc
          if position == 0
            if !results.first_page?
              results_prev_page = search_with_solr(fields, order, with, results.previous_page)
              prev_item = results_prev_page.last
              # the previous item is one the previous page, we also need to return the page nb
              prev_page = results.previous_page
            end
          else
            prev_item = results[position - 1]
          end

          # get the next item in the search
          if position == MAX_PER_PAGE - 1
            if !results.last_page?
              results_next_page = search_with_solr(fields, order, with, results.next_page)
              next_item = results_next_page.first
              # return the page number too
              next_page = results.next_page
            end
          else
            next_item = results[position + 1]
          end

          return prev_item, next_item, prev_page, next_page
        end

      private

        def search_with_solr(fields = [], order = {}, with_filter = {}, page = 1, per_page = MAX_PER_PAGE)

          model=self.to_s

          solr_results = self.solr_search do
            if !order.empty?
              order_by order[:field], order[:order]
            end

            fields.each do |f|
              if f[:fields].empty?
                without(:record_type, 2) if model=="Source"
                fulltext f[:value]
              else
                without(:record_type, 2) if model=="Source"
                fulltext f[:value], :fields => f[:fields]
              end
            end

            with_filter.each do |field, value|
              with(field, value)
            end

            paginate :page => page, :per_page => per_page
          end
          return solr_results.results

        end # search_with_solr

        def unpack_params(params)
          fields = []
          order = {}
          with = {}
          page = params.has_key?(:page) ? params[:page] : 1

          if params.has_key?(:order)
            order = params[:order].include?("_asc") ? "asc" : "desc"
            field = params[:order].gsub("_#{order}", "")

            if field != "id"
              field = field + "_order"
            end

            order = {:field => field.underscore.to_sym, :order => order.to_sym}
          end

          options = params[:q]
          if options
            options.keys.each do |k|

              # Skip to the next one if the value
              # for this query is empty
              next if options[k] == ""

              # Barebones field parser
              # Accepts only one field name
              # Whith the _contains predicate
              # E.g. :full_title_contains
              # Strip the ransack predicate
              # To do any field searches,
              # just use another predicate
              # and no field will be used
              f = []
              if k.to_s.match("contains") # :filter xxx_contains
                field = k.to_s.gsub("_contains", "")
                f << field.underscore.to_sym
                fields << {:fields => f, :value => options[k]}
              elsif k.to_s.match("with_integer") # :filter zzz_with_integer
                # The field to filter with is
                # in the value
                field, id = options[k].split(":")
                with[field] = id
              else # all the other ransack predicates
                # make an "any" search, field is empty
                # so the value is applied to all
                fields << {:fields => [], :value => options[k]}
              end

            end
          else
            # if no field is specified
            # return all elements
            fields <<{:fields => [], :value => "*"}
            # If ordering is not given
            # order by id, default in sunspot is
            # by :score
            # Order descending as this is the default
            # ordering for columns in activerails
            if order.empty?
              order = {:field => :id, :order => :desc}
            end
          end

          return fields, order, with, page
        end

      end
    end
  end
end

ActiveRecord::Base.extend Muscat::Adapters::ActiveRecord::Base
