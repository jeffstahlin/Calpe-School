class Gallery < ActiveRecord::Base
  belongs_to :event
  has_many :uploads, :dependent => :destroy
  
end
