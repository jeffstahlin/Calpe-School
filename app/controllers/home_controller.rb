class HomeController < ApplicationController
  
  def index
  	@page = Page.find_by_name(params[:name].gsub(/-/, " "))||Page.find_by_name("home")
  	case params[:name]
  		when "Photo-Gallery" then  @galleries = Gallery.find(:all)
  	end	
  end
  

end
