class Admin::GalleriesController < Admin::BaseController
  def index
    @galleries = Gallery.find(:all)
  end

  def show
		@gallery = Gallery.find_by_id(params[:id])
		@uploads = @gallery.uploads
		@upload = Upload.new
  end

  def new
		@event = Page.find_by_id(params[:page_id])
		@gallery = Gallery.new
  end

	def create
	 @gallery = Gallery.new(params[:gallery])
	 respond_to do |format|
		 if @gallery.save
			
			 format.html {
			   
			     flash[:notice] = 'Event Gallery was successfully created.'
			     redirect_to admin_galleries_path
			   
			   
			  }
			
			 format.xml  { render :xml => @gallery, :status => :created, :gallery => @gallery }
		 else
			 format.html { render :action => "new" }
			 format.xml  { render :xml => @gallery.errors, :status => :unprocessable_entity }
		 end
	 end
	end

  def edit
		@page = Page.find_by_id(params[:page_id])
		@gallery = Gallery.find_by_id(params[:id])
  end
  
	def update
	@gallery = Gallery.find_by_id(params[:id])
		respond_to do |format|
		 if @gallery.update_attributes(params[:gallery])
			flash[:notice] = 'gallery was successfully UPDATED.'
			format.html {
				 
				   flash[:notice] = 'gallery was successfully updated.'
				   redirect_to(admin_galleries_path)
				
				}
			format.xml  { head :ok }
		 else
			 format.html { render :action => "edit" }
			 format.xml  { render :xml => @gallery.errors, :status => :unprocessable_entity }
		 end
		end
	end


	 def destroy
     @gallery = Gallery.find(params[:id])
     @gallery.destroy

     respond_to do |format|
       format.html { redirect_to(admin_galleries_path ) }
       format.xml  { head :ok }
     end
   end
end
