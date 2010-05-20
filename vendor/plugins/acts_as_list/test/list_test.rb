require 'test/unit'

require 'rubygems'
gem 'activerecord', '>= 2.1'
require 'active_record'

require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

#ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new(STDERR)
#ActiveRecord::Base.colorize_logging = false

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.integer :pos
      t.belongs_to :parent
      t.timestamps
    end
    create_table :widgets do |t|
      t.string :type
      t.integer :pos
      t.belongs_to :parent
      t.timestamps
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
end

class ListMixin < Mixin
  acts_as_list :column => "pos", :scope => :parent
  def self.table_name() 'mixins' end
end

class ListMixinSub1 < ListMixin
end

class ListMixinSub2 < ListMixin
end

class ListWithStringScopeMixin < ActiveRecord::Base
  acts_as_list :column => "pos", :scope => 'parent_id = #{ parent_id }'

  def self.table_name() "mixins" end
end

class Widget < ActiveRecord::Base
  acts_as_list :column => "pos", :scope => :parent
end
class WidgetA < Widget
end
class WidgetB < Widget
end


class ListTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |counter| ListMixin.create! :pos => counter, :parent_id => 5 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    ListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_next_prev
    assert_equal ListMixin.find(2), ListMixin.find(1).lower_item
    assert_nil ListMixin.find(1).higher_item
    assert_equal ListMixin.find(3), ListMixin.find(4).higher_item
    assert_nil ListMixin.find(4).lower_item
  end

  def test_injection
    item = ListMixin.new(:parent_id => 1)
    expected_options = { :conditions => { :parent_id => 1 } }
    assert_equal expected_options, ListMixin.listed_with(item).proxy_options
    assert_equal "pos", item.position_column
  end

  def test_insert
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 0)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_insert_at
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos

    new4 = ListMixin.create(:parent_id => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ListMixin.create(:parent_id => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos

    ListMixin.find(1).destroy

    assert_equal [3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(3).pos
    assert_equal 2, ListMixin.find(4).pos
  end

  def test_with_string_based_scope
    new = ListWithStringScopeMixin.create(:parent_id => 500)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_nil_scope
    new1, new2, new3 = ListMixin.create, ListMixin.create, ListMixin.create
    new2.move_higher
    assert_equal [new2, new1, new3], ListMixin.find(:all, :conditions => 'parent_id IS NULL', :order => 'pos')
  end


  def test_remove_from_list_should_then_fail_in_list?
    assert_not_nil ListMixin.find(1).in_list?
    ListMixin.find(1).remove_from_list
    assert_nil ListMixin.find(1).in_list?
  end

  def test_remove_from_list_should_set_position_to_nil
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).remove_from_list

    assert_equal [2, 1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1,   ListMixin.find(1).pos
    assert_equal nil, ListMixin.find(2).pos
    assert_equal 2,   ListMixin.find(3).pos
    assert_equal 3,   ListMixin.find(4).pos
  end

  def test_remove_before_destroy_does_not_shift_lower_items_twice
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).remove_from_list
    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos
  end

end

class ListSubTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |i| [ListMixinSub1, ListMixinSub2][i % 2].create! :pos => i, :parent_id => 5000 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    ListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
  end

  def test_next_prev
    assert_equal ListMixin.find(2), ListMixin.find(1).lower_item
    assert_nil ListMixin.find(1).higher_item
    assert_equal ListMixin.find(3), ListMixin.find(4).higher_item
    assert_nil ListMixin.find(4).lower_item
  end

  def test_injection
    item = ListMixin.new("parent_id"=>1)
    expected_options = { :conditions => { :parent_id => 1 } }
    assert_equal expected_options, ListMixin.listed_with(item).proxy_options
    assert_equal "pos", item.position_column
  end

  def test_insert_at
    new = ListMixin.create("parent_id" => 20)
    assert_equal 1, new.pos

    new = ListMixinSub1.create("parent_id" => 20)
    assert_equal 2, new.pos

    new = ListMixinSub2.create("parent_id" => 20)
    assert_equal 3, new.pos

    new4 = ListMixin.create("parent_id" => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ListMixinSub1.create("parent_id" => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos

    ListMixin.find(1).destroy

    assert_equal [3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(3).pos
    assert_equal 2, ListMixin.find(4).pos
  end
  
  def test_moving_to_bottom_on_single_item_list
    mixin = ListMixin.create! :pos => 1, :parent_id => 6
    assert_nothing_raised(NoMethodError) { mixin.move_to_bottom }
    assert_equal(1, mixin.pos)
  end
  
  
end

class ListOrderByIdsTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..8).each { |i| [ListMixinSub1, ListMixinSub2][i % 2].create! :pos => i, :parent_id => 5000 }
  end

  def teardown
    teardown_db
  end

  def test_reorder_by_ids_simple
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    ListMixin.order_by_ids([3, 1, 8, 4, 2, 7, 6, 5])
    assert_equal [3, 1, 8, 4, 2, 7, 6, 5], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
  end

  def test_reorder_by_ids_as_strings
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    ListMixin.order_by_ids(%w(3 1 8 4 2 7 6 5))
    assert_equal [3, 1, 8, 4, 2, 7, 6, 5], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
  end

  def test_reorder_by_ids_with_extra_items
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    ListMixin.order_by_ids([3, 9, 1, 10, 8, 20, 4, 11, 2, 0, 7, 3, 3, 3, 6, 5])
    assert_equal [3, 1, 8, 4, 2, 7, 6, 5], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    assert_equal [2, 5, 1, 4, 8, 7, 6, 3], ListMixin.find(:all, :conditions => 'parent_id = 5000').map(&:pos)
  end

  def test_reorder_by_ids_without_sertain_items
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    ListMixin.order_by_ids([3, 1, 8, 4, 2, 7, 6, 5])
    assert_equal [3, 1, 8, 4, 2, 7, 6, 5], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    ListMixin.order_by_ids([1, 4, 2, 5])
    assert_equal [1, 4, 2, 5, 3, 8, 7, 6], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    assert_equal [1, 3, 5, 2, 4, 8, 7, 6], ListMixin.find(:all, :conditions => 'parent_id = 5000').map(&:pos)
  end

  def test_reorder_by_ids_with_nil_positions
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    ListMixin.find(1).update_attribute(:pos, nil)
    ListMixin.find(4).update_attribute(:pos, nil)
    ListMixin.find(8).update_attribute(:pos, nil)
    ListMixin.order_by_ids([8, 7, 6, 5])
    assert_equal [8, 7, 6, 5, 1, 4, 2, 3], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
  end
end

class WidgetTest < Test::Unit::TestCase

  def setup
    setup_db
  end

  def teardown
    teardown_db
  end

  def test_widgets_of_many_types_should_be_in_same_list
    (1..8).each { |i| [WidgetA, WidgetB][i % 2].create! :parent_id => 5000 }

    assert_equal [1, 2, 3, 4, 5, 6, 7, 8], Widget.all.map(&:pos)
  end
end
