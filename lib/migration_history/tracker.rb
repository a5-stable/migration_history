# frozen_string_literal: true

require "migration_history/extractor"

module MigrationHistory
  class Tracker
    attr_accessor :migration_info, :migration_file_dir

    def initialize(migration_file_dir = nil)
      @migration_file_dir = migration_file_dir || "db/migrate"
      @migration_info = {}
    end

    def setup!
      migration_path = File.expand_path(File.join(Dir.pwd, @migration_file_dir))
      migration_files = Dir.glob(File.join(migration_path, "*.rb"))

      migration_files.each do |file|
        result = extract_migration_methods(file)
        @migration_info[result[:class_name]] = result
        @migration_info[result[:class_name]][:timestamp] = File.basename(file).split("_").first.to_i
      end
    end

    private
      def extract_migration_methods(file_path)
        code = File.read(file_path)
        ast = Parser::CurrentRuby.parse(code)
        return unless ast

        visitor = MigrationHistory::Extractor.new
        visitor.process(ast)

        {
          file_path: File.basename(file_path),
          class_name: visitor.current_class,
          actions: visitor.actions
        }
      end
  end
end
