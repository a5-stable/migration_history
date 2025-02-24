# frozen_string_literal: true

require "migration_history/formatter/base"

module MigrationHistory
  module Formatter
    class JsonFormatter < Base
      def format(result_set)
        File.open(File.join(Dir.pwd, output_file_name_with_extension), "wb") do |file|
          file.puts result_set.original_result.to_json
        end
      end

      def file_extension
        "json"
      end
    end
  end
end
