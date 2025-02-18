require "migration_history/result_set"
require "migration_history/tracker"

module MigrationHistory
  module QueryMethods
    @migration_file_dir = "db/migrate"
    @tracker = nil

    module ClassMethods
      attr_accessor :migration_file_dir

      def filter(table_name, column_name = nil, action_name = nil)
        table_name = table_name.to_sym
        column_name = column_name.to_sym if column_name
        action_name = action_name.to_sym if action_name
        raise InvalidError.new("Table name is required") unless table_name

        found_migration_info = {}
        tracker.migration_info.values.each do |v|
          if v[:actions].to_a.any? { |action|
              action.dig(:details, :table_name) == table_name &&
                (column_name.nil? || action.dig(:details, :column_name) == column_name) &&
                (action_name.nil? || action[:action] == action_name)
            }

            found_migration_info[v[:class_name]] = v
          end
        end

        ResultSet.new(found_migration_info)
      end

      def all
        ResultSet.new(tracker.migration_info)
      end

      def tracker
        @tracker ||= Tracker.new(migration_file_dir).tap(&:setup!)
      end

      def reload!
        @tracker = nil
        tracker
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
