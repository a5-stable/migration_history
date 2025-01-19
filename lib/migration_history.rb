# frozen_string_literal: true

require "migration_history/cli"
require "migration_history/tracker"
require "migration_history/formatter/base"
require "migration_history/formatter/html_formatter"
require "active_record"
require "rails"

module MigrationHistory
  class InvalidError
    def initialize(message)
      @message = message
    end
  end

  def self.for_table_created(table_name)
    raise InvalidError.new("Table name is required") unless table_name

    filter(table_name, nil, "create_table")
  end

  def self.for_column_added(table_name, column_name)
    unless table_name && column_name
      raise InvalidError.new("Table name and column name are required")
    end

    filter(table_name, column_name, "add_column")
  end

  def self.filter(table_name, column_name = nil, action_name = nil)
    table_name = table_name.to_sym
    column_name = column_name.to_sym if column_name
    action_name = action_name.to_sym if action_name
    raise InvalidError.new("Table name is required") unless table_name

    a = Tracker.new
    a.setup!
    found_migration_info = a.migration_info.values.select do |v|
      v.dig(:details, :table_name) == table_name &&
        (column_name.nil? || v.dig(:details, :column_name) == column_name) &&
        (action_name.nil? || v[:action] == action_name)
    end

    ResultSet.new(found_migration_info)
  end

  def self.all
    a = Tracker.new
    a.setup!

    ResultSet.new(a.migration_info)
  end

  class ResultSet
    attr_accessor :original_result

    def initialize(original_result)
      @original_result = original_result
    end

    def format!
      formatter = HTMLFormatter.new
      formatter.format(self)
    end
  end
end
