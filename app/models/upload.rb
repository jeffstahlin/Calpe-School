class Upload < ActiveRecord::Base
	belongs_to :gallery
	acts_as_list :scope => :gallery

	has_attached_file :photo,
		                :styles => {
		                  :pagesize => ["600x400#", :jpg],          :thumb => ["125x100#", :jpg],
		                },:processors => [:cropper],:convert_options => {  
		                    :thumb => "-resize 120x74 -gravity center"
		              	},
		                :storage => :s3,
		                :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
		                :path => "assets/events/gallery/:id/:style/:basename.jpg"
		                
	attr_accessor :crop_x, :crop_y, :crop_w, :crop_h     



	# before_edit :reset_photo
	after_update  :reprocess_photo, :if => :cropping?

	def cropping?
	 !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
	end  

	def photo_geometry(style = :original)
	 @geometry ||= {}
	 @geometry[style] ||= Paperclip::Geometry.from_file(photo.to_file(style))
	end

	private
	 def reprocess_photo
		 photo.reprocess!
	 end
	 def reset_photo
		 photo.reprocess!
	 end

	def url(style=:thumb)
		if processing
		  still_processing_image_path
		else
		  self.photo.url(style)
		end
	end
end


