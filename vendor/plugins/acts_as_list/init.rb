require "#{ File.dirname __FILE__ }/lib/active_record/acts/list"
ActiveRecord::Base.extend ActiveRecord::Acts::List
