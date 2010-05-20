class Admin::PagesController < Admin::BaseController
  def index
     @pagetitle = "Admin - Static pages"
    
		if params[:parent] 
			@parent = Page.find_by_id(params[:parent])
			@pages = Page.find_sub(params[:parent])
		else
			@pages = Page.find_main
		end
     respond_to do |format|
       format.html # index.html.erb
       format.xml  { render :xml => @pages }
     end
   end

   # GET /pages/1
   # GET /pages/1.xml
   def show
     @page = Page.find(params[:id])  
     respond_to do |format|
       format.html # show.html.erb
       format.xml  { render :xml => @page }
     end
   end

   # GET /pages/new
   # GET /pages/new.xml
   def new
     @page = Page.new

     respond_to do |format|
       format.html # new.html.erb
       format.xml  { render :xml => @page }
     end
   end

   # GET /pages/1/edit
   def edit
     @page = Page.find(params[:id])
   end

   # POST /pages
   # POST /pages.xml
   def create
     @page = Page.new(params[:page])

     respond_to do |format|
       if @page.save
         flash[:notice] = 'Page was successfully created.'
         format.html {
           
             flash[:notice] = 'Category was successfully created.'
             redirect_to(admin_page_path(@page))
           
           
          }
        
         format.xml  { render :xml => @page, :status => :created, :location => @page }
       else
         format.html { render :action => "new" }
         format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
       end
     end
   end

   # PUT /pages/1
   # PUT /pages/1.xml
   def update
     @page = Page.find(params[:id])
     respond_to do |format|
       if @page.update_attributes(params[:page])
        flash[:notice] = 'Page was successfully UPDATED.'
        format.html {
           
             flash[:notice] = 'Category was successfully updated.'
             redirect_to(admin_page_path(@page))
          
          }
        format.xml  { head :ok }
       else
         format.html { render :action => "edit" }
         format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
       end
     end
   end

   # DELETE /pages/1
   # DELETE /pages/1.xml
   def destroy
     @page = Page.find(params[:id])
     @page.destroy

     respond_to do |format|
       format.html { redirect_to(admin_pages_path) }
       format.xml  { head :ok }
     end
   end
   
end
