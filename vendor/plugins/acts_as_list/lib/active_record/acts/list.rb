module ActiveRecord
  module Acts #:nodoc:
    # This +acts_as+ extension provides the capabilities for sorting and reordering a number of objects in a list.
    # The class that has this specified needs to have a +position+ column defined as an integer on
    # the mapped database table.
    #
    # Todo list example:
    #
    #   class TodoList < ActiveRecord::Base
    #     has_many :todo_items, :order => "position"
    #   end
    #
    #   class TodoItem < ActiveRecord::Base
    #     belongs_to :todo_list
    #     acts_as_list :scope => :todo_list
    #   end
    #
    #   todo_list.first.move_to_bottom
    #   todo_list.last.move_higher
    module List
      # Configuration options are:
      #
      # * +column+ - specifies the column name to use for keeping the position integer (default: +position+)
      # * +scope+ - restricts what is to be considered a list. Given a symbol, it'll attach <tt>_id</tt>
      #   (if it hasn't already been added) and use that as the foreign key restriction. It's also possible
      #   to give it an entire string that is interpolated if you need a tighter scope than just a foreign key.
      #   Example: <tt>acts_as_list :scope => 'todo_list_id = #{todo_list_id} AND completed = 0'</tt>
      def acts_as_list(options = {})
        configuration = { :column => :position, :scope => '1 = 1' }
        configuration.update options if options.is_a? Hash

        scope = configuration.delete :scope
        named_scope :listed_with, case scope
            when Symbol
              scope = :"#{ scope }_id" if "#{ scope }"[-3..-1] != '_id'
              proc {|r| { :conditions => { scope => r.send(scope) } } }
            when String
              proc {|r| { :conditions => r.instance_eval(%Q'"#{ scope }"') } }
            when Proc
              proc {|r| { :conditions => r.instance_eval(&scope) } }
            else
              raise "Unknown type of scope #{scope.inspect}"
            end

        cattr_reader :acts_as_list_class
        class_variable_set :@@acts_as_list_class, self
        cattr_reader :position_column
        # Assigning a class variable literally from an extended class method is HARD.  http://www.ruby-forum.com/topic/97333
        class_variable_set :@@position_column, configuration[:column].to_s.dup

        include ActiveRecord::Acts::List::InstanceMethods
        extend ActiveRecord::Acts::List::SingletonMethods
        before_destroy :remove_from_list
        before_create :add_to_list_bottom
        default_scope :order => position_column
      end

      module SingletonMethods
        def order_by_ids(ids)
          list_by_id = listed_with(find(ids.first)).all.index_by(&:id)
          transaction do
            position = 1
            ids.each_with_index do |id, i|
              if item = list_by_id.delete(id.to_i)
                item.update_attributes(position_column => position) if item[position_column] != position
                position += 1
              end
            end
            list_by_id.values.sort_by{ |item| item[position_column] || 0 }.each do |item|
              item.update_attributes(position_column => position) if item[position_column] != position
              position += 1
            end
          end
        end
      end

      # All the methods available to a record that has had <tt>acts_as_list</tt> specified. Each method works
      # by assuming the object to be the item in the list, so <tt>chapter.move_lower</tt> would move that chapter
      # lower in the list of all chapters. Likewise, <tt>chapter.first?</tt> would return +true+ if that chapter is
      # the first in the list of all chapters.
      module InstanceMethods
        # Insert the item at the given position (defaults to the top position of 1).
        def insert_at(position = 1)
          insert_at_position position
        end

        # Swap positions with the next lower item, if one exists.
        def move_lower
          acts_as_list_class.transaction do
            lower_item.try(:decrement_position) and increment_position
          end
        end

        # Swap positions with the next higher item, if one exists.
        def move_higher
          acts_as_list_class.transaction do
            higher_item.try(:increment_position) and decrement_position
          end
        end

        # Move to the bottom of the list. If the item is already in the list, the items below it have their
        # position adjusted accordingly.
        def move_to_bottom
          transaction_if_listed do
            decrement_positions_on_lower_items
            assume_bottom_position
          end
        end

        # Move to the top of the list. If the item is already in the list, the items above it have their
        # position adjusted accordingly.
        def move_to_top
          transaction_if_listed do
            increment_positions_on_higher_items
            assume_top_position
          end
        end

        # Removes the item from the list.
        def remove_from_list
          transaction_if_listed do
            decrement_positions_on_lower_items
            update_attribute position_column, nil
          end
        end

        # Increase the position of this item without adjusting the rest of the list.
        def increment_position
          update_attribute position_column, lower_position if in_list?
        end

        # Decrease the position of this item without adjusting the rest of the list.
        def decrement_position
          update_attribute position_column, higher_position if in_list?
        end

        # Return +true+ if this object is the first in the list.
        def first?
          in_list? && send(position_column) == 1
        end

        # Return +true+ if this object is the last in the list.
        def last?
          in_list? && send(position_column) == bottom_position_in_list
        end

        # Returns the position of the next higher item
        def higher_position
          send(position_column).to_i - 1
        end
        # Returns the position of the next lower item
        def lower_position
          send(position_column).to_i + 1
        end

        # Return the next higher item in the list.
        def higher_item
          if in_list?
            higher = "#{ position_column } = #{ higher_position }"
            acts_as_list_class.listed_with(self).first :conditions => higher
          end
        end

        # Return the next lower item in the list.
        def lower_item
          if in_list?
            higher = "#{ position_column } = #{ lower_position }"
            acts_as_list_class.listed_with(self).first :conditions => higher
          end
        end

        # Test if this record is in a list
        def in_list?
          send position_column
        end

        # Executes given block in transaction if record is in a list
        def transaction_if_listed
          block_given? && in_list? || return
          acts_as_list_class.transaction { yield }
        end

        private
        def add_to_list_top
          increment_positions_on_all_items
        end

        def add_to_list_bottom
          self[position_column] = bottom_position_in_list.to_i + 1
        end

        # Returns the bottom position number in the list.
        #   bottom_position_in_list    # => 2
        def bottom_position_in_list(*except)
          options = {}
          options[:conditions] = ["#{ acts_as_list_class.primary_key } NOT IN (?)",
              except.map { |e| e.id }] unless except.empty?

          (acts_as_list_class.listed_with(self).maximum position_column, options) || 0 #In case the exception is the only thing in the list
        end

        # Returns the bottom item
        def bottom_item(*except)
          options = {:order => "#{ position_column } DESC"}
          options[:conditions] = ["#{ acts_as_list_class.primary_key } NOT IN (?)",
              except.map { |e| e.id }] unless except.empty?

          acts_as_list_class.listed_with(self).first options
        end

        # Forces item to assume the bottom position in the list.
        def assume_bottom_position
          update_attribute position_column, bottom_position_in_list(self) + 1
        end

        # Forces item to assume the top position in the list.
        def assume_top_position
          update_attribute position_column, 1
        end

        # This has the effect of moving all the higher items up one.
        def decrement_positions_on_higher_items(position)
          acts_as_list_class.listed_with(self).update_all(
          "#{ position_column } = (#{ position_column } - 1)",
          "#{ position_column } <= #{ position }"
          )
        end

        # This has the effect of moving all the lower items up one.
        def decrement_positions_on_lower_items
          acts_as_list_class.listed_with(self).update_all(
          "#{ position_column } = (#{ position_column } - 1)",
          "#{ position_column } > #{ send position_column }"
          ) if in_list?
        end

        # This has the effect of moving all the higher items down one.
        def increment_positions_on_higher_items
          acts_as_list_class.listed_with(self).update_all(
          "#{ position_column } = (#{ position_column } + 1)",
          "#{ position_column } < #{ send position_column }"
          ) if in_list?
        end

        # This has the effect of moving all the lower items down one.
        def increment_positions_on_lower_items(position)
          acts_as_list_class.listed_with(self).update_all(
          "#{ position_column } = (#{ position_column } + 1)",
          "#{ position_column } >= #{ position }"
          )
        end

        # Increments position (<tt>position_column</tt>) of all items in the list.
        def increment_positions_on_all_items
          acts_as_list_class.listed_with(self).
              update_all "#{ position_column } = (#{ position_column } + 1)"
        end

        def insert_at_position(position)
          acts_as_list_class.transaction do
            remove_from_list
            increment_positions_on_lower_items position
            update_attribute position_column, position
          end
        end
      end
    end
  end
end
