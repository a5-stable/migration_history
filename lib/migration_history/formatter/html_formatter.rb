# frozen_string_literal: true

require "migration_history/formatter/base"

module MigrationHistory
  module Formatter
    class HtmlFormatter < Base
      def format(result_set)
        File.open(File.join(Dir.pwd, output_file_name_with_extension), "wb") do |file|
          file.puts template("template").result(binding)
        end
      end

      def template(name)
        ERB.new(File.read(File.join(File.dirname(__FILE__), "../../../views/", "#{name}.erb")))
      end

      def file_extension
        "html"
      end
    end
  end
end
