class AddPositionToUploads < ActiveRecord::Migration
  def self.up
    add_column :uploads, :position, :integer
  end

  def self.down
    remove_column :uploads, :position
  end
end
