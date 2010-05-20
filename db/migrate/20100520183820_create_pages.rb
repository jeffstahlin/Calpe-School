class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string :title
      t.string :name
      t.string :navlabel
      t.text :body
      t.integer :position
      t.integer :parent_id

      t.timestamps
    end
  end

  def self.down
    drop_table :pages
  end
end
