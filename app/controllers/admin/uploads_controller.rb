class Admin::UploadsController < ApplicationController

	def	create
	 @upload = Upload.new(params[:upload])

 	 @gallery = Gallery.find_by_id(params[:gallery_id])
	 @upload.gallery_id = @gallery.id			
		respond_to do |format|
    	if @upload.save
			
	   # =>  @upload.queue_move_to_s3

			
			 format.html {
			   
			     flash[:notice] = 'Event Gallery was successfully created.'
			     redirect_to admin_gallery_path(@gallery.id)
			   
			   
			  }
			
			 format.xml  { render :xml => @upload, :status => :created, :upload => @upload }
		 else
			 format.html { render :action => "new" }
			 format.xml  { render :xml => @upload.errors, :status => :unprocessable_entity }
		 end
	 end
	end 

 def destroy
     @upload = Upload.find(params[:id])
     @upload.destroy

     respond_to do |format|
       format.html { redirect_to(admin_gallery_path(@upload.gallery)) }
       format.xml  { head :ok }
     end
   end
end