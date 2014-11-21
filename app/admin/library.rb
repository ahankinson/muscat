ActiveAdmin.register Library do
  
  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_library_sigla)}

  collection_action :autocomplete_library_siglum, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :library, :siglum
    
    after_destroy :check_model_errors
    
    def check_model_errors(object)
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
    
    def permitted_params
      params.permit!
    end
    
    def show
      @library = Library.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = Library.near_items_as_ransack(params, @library)
    end
    
    
    def index
      @results = Library.search_as_ransack(params)
      
      index! do |format|
        @libraries = @results
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
         collection: proc{Folder.where(folder_type: "Library").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  
  index do
    selectable_column
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_siglum), :siglum
    column (I18n.t :filter_location_and_name), :name
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
      row (I18n.t :filter_siglum) { |r| r.siglum }
      row (I18n.t :filter_address) { |r| r.address }
      row (I18n.t :filter_url) { |r| r.url }
      row (I18n.t :filter_phone) { |r| r.phone }
      row (I18n.t :filter_email) { |r| r.email }    
    end
    active_admin_embedded_source_list( self, library, params[:qe], params[:src_list_page] )
  end
  
  sidebar I18n.t(:search_sources), :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
 
  form do |f|
    f.inputs I18n.t(:details) do
      f.input :siglum, :label => (I18n.t :filter_siglum)
      f.input :name, :label => (I18n.t :filter_name)
      f.input :address, :label => (I18n.t :filter_address)

    end
    f.inputs I18n.t(:content) do
      f.input :url, :label => (I18n.t :filter_url)
      f.input :phone, :label => (I18n.t :filter_phone)
      f.input :email, :label => (I18n.t :filter_email)
    end
    f.actions
  end
  
end
