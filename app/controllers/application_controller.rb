class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'opac'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :set_locale
  
  # Find out and set the locale, store into a cookie
  def set_locale 
    # We do not check if the locale is available. The list is actually set in the
    # menu (see active_admin.rb) 
    if params[:locale] ## && AVAILABLE_LOCALES.include?(params[:locale])
    # user is changing locale, keep it for the session and in a cookie
      session[:locale] = params[:locale]
      cookies[:locale] = { :value => session[:locale], :expires => 30.days.from_now }
    elsif !session[:locale]
      # no locale for the session yet, use cookie or http_header (or default)
      if (cookies[:locale]) # && AVAILABLE_LOCALES.include?(cookies[:locale])
        session[:locale] = cookies[:locale] 
      else
        #logger.debug "HTTP_ACCEPT_LANGUAGE:#{request.env['HTTP_ACCEPT_LANGUAGE']}" 
        session[:locale] = _locale_from_http_header
        cookies[:locale] = { :value => session[:locale], :expires => 30.days.from_now }
      end
    end   
    #logger.debug "LOCALE", I18n.locale
    I18n.locale = session[:locale]
  end 
  
  def restore_search_filters  
  end
  
  def save_search_filters  
  end

end
