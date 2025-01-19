# frozen_string_literal: true

module MigrationHistory
  module Formatter
    class HTMLFormatter < Base
      attr_accessor :output_file_name

      def initialize(_output_file_name = nil)
        @output_file_name ||= "migration_history.html"
      end

      def format(result_set)
        File.open(File.join(Dir.pwd, output_file_name), "wb") do |file|
          file.puts template("template").result(binding)
        end
      end

      def template(name)
        ERB.new(File.read(File.join(File.dirname(__FILE__), "../../../views/", "#{name}.erb")))
      end
    end
  end
end
