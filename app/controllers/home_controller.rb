class HomeController < ApplicationController
  
  def index
  	@page = Page.find_by_name(params[:name])||Page.find_by_name("home")
  end

end
