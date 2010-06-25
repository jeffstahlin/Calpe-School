# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  before_filter :get_pages
  
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

	layout'main'
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

	def get_pages
		@pages = Page.find_main
	end

end
