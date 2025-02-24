# frozen_string_literal: true

module MigrationHistory
  module Formatter
    class Base
      attr_accessor :output_file_name

      DEFAULT_OUTPUT_FILE_NAME = "migration_history"

      def initialize
        @migration_actions = []
        @output_file_name ||= DEFAULT_OUTPUT_FILE_NAME
      end

      def format(result_set)
        raise NotImplementedError
      end

      def file_extension
        raise NotImplementedError
      end

      def output_file_name_with_extension
        "#{output_file_name}.#{file_extension}"
      end
    end
  end
end
