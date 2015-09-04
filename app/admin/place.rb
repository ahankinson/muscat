ActiveAdmin.register Place do
  # Temporary hide menu item because place model has to be configured first
  menu false
  #menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_places)}

  # Remove mass-delete action
  batch_action :destroy, false

  collection_action :autocomplete_place_name, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do

    autocomplete :place, :name

    after_destroy :check_model_errors
    before_create do |item|
      item.user = current_user
    end

    def check_model_errors(object)
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end

    def permitted_params
      params.permit!
    end

    def show
      @place = Place.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = Place.near_items_as_ransack(params, @place)
    end

    def index
      @results = Place.search_as_ransack(params)

      index! do |format|
        @places = @results
        format.html
      end
    end

  end

  # Include the folder actions
  include FolderControllerActions

  ###########
  ## Index ##
  ###########

  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string

  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select,
         collection: proc{Folder.where(folder_type: "Place").collect {|c| [c.name, "folder_id:#{c.id}"]}}

  index do
    selectable_column
    column (I18n.t :filter_id), :id
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_country), :country
    column (I18n.t :filter_sources), :src_count
    actions
  end

  ##########
  ## Show ##
  ##########

  show do
    active_admin_navigation_bar( self )
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :filter_country) { |r| r.country }
      row (I18n.t :filter_district) { |r| r.district }
    end
    active_admin_embedded_source_list( self, place, params[:qe], params[:src_list_page] )
    active_admin_user_wf( self, place )
    active_admin_navigation_bar( self )
  end

  sidebar I18n.t(:search_sources), :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end

  ##########
  ## Edit ##
  ##########

  form do |f|
    f.inputs do
      f.input :name, :label => (I18n.t :filter_name)
      f.input :country, :label => (I18n.t :filter_country), :as => :string # otherwise country-select assumed
      f.input :district, :label => (I18n.t :filter_district)
      f.input :lock_version, :as => :hidden
    end
    f.actions
  end

end
