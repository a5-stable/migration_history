# frozen_string_literal: true

require "thor"
require "erb"
require "migration_history"
require "migration_history/formatter/html_formatter"
require "migration_history/formatter/json_formatter"
require "time"

module MigrationHistory
  class CLI < Thor
    desc "filter", "Retrieve migration history with filtering"
    option :table, required: true, desc: "Table name"
    option :column, required: false, desc: "Column name"
    option :action, required: false, desc: "Action name"
    option :output, required: false, desc: "HTML output file name"
    def filter
      table_name = options[:table]
      column_name = options[:column]
      action_name = options[:action]

      result = MigrationHistory.filter(table_name, column_name, action_name)

      if options[:output]
        generate_html(result, options[:output])
      else
        result.original_result.each do |_, entry|
          timestamp = Time.strptime(entry[:timestamp], "%Y%m%d%H%M%S") rescue entry[:timestamp]
          puts "ClassName: #{entry[:class_name]}, Timestamp: #{timestamp}"
        end
      end
    end

    desc "all", "Retrieve all migration history"
    option :format, required: false, desc: "Output format"
    option :output, required: false, desc: "HTML output file name"
    def all
      result = MigrationHistory.all

      if options[:format]
        formatter = find_formatter(options[:format])
        formatter.output_file_name = options[:output] if options[:output]

        formatter.format(result)
        puts "Output to #{formatter.output_file_name_with_extension}"
      else
        result.original_result.each do |_, entry|
          timestamp = Time.strptime(entry[:timestamp], "%Y%m%d%H%M%S") rescue entry[:timestamp]
          puts "ClassName: #{entry[:class_name]}, Timestamp: #{timestamp}"
        end
      end
    end

    private
      def find_formatter(format)
        Object.const_get("MigrationHistory::Formatter::#{format.capitalize}Formatter").new
      rescue
        raise ArgumentError, "Invalid format: #{format}, available formats: html, json"
      end
  end
end
