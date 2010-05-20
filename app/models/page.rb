class Page < ActiveRecord::Base
 has_many :subpages, :class_name => 'Page', :foreign_key => 'parent_id'
 belongs_to :parent, :class_name => 'Page', :foreign_key => 'parent_id'

  #has_many :galleries
  
  def self.find_main
    Page.find(:all, :conditions => ['parent_id IS NULL'], :order => 'position')
  end

  def self.find_sub(pid)
    Page.find(:all, :conditions => ['parent_id = ?', pid], :order => 'position')
  end
	  
end
