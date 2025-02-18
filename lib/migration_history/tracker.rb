# frozen_string_literal: true

require "migration_history/method_overrides"
require "migration_history/method_extracter"

module MigrationHistory
  class Tracker
    attr_accessor :migration_info, :migration_file_dir
    def initialize(migration_file_dir = nil)
      @migration_info ||= []
      @migration_file_dir = migration_file_dir || "db/migrate"
    end

    def setup!(history = Tracker.new)
      migration_path = File.expand_path(File.join(Dir.pwd, @migration_file_dir), __dir__)
      migration_files = Dir.glob(File.join(migration_path, "*.rb"))

      migration_histories = {}
      ActiveRecord::Migration.prepend(MethodOverrides)

      migration_files.map do |file|
        # ファイル内で定義されているクラス名を抽出
        require file
        result = extract_migration_methods(file)
        puts "Processing: #{result}"
        class_name = result[:class_name]
        methods = result[:methods]

        migration_histories[class_name] ||= {}
        ignore_unknown_methods(methods)

        migration_history = {
          timestamp: File.basename(file).split("_").first.to_i,
          class_name: class_name,
          migration_file_name: file.split("/").last,
          actions: []
        }

        result = Object.const_get(class_name).new.exec_migration(nil, :up)
        if result
          if result.is_a?(Array)
            migration_history[:actions] += result
          else
            migration_history[:actions] << result
          end
        end

        migration_histories[class_name] = migration_history
      rescue => e
        puts "Error: #{e.message}"
      end

      @migration_info = migration_histories

      nil
    end

    private
      require "parser/current"

      def extract_migration_methods(file_path)
        code = File.read(file_path)
        ast = Parser::CurrentRuby.parse(code)

        extractor = MigrationHistory::MigrationMethodExtractor.new
        extractor.process(ast)

        {
          file_path: file_path,
          class_name: extractor.current_class,
          methods: extractor.methods
        }
      end

      def ignore_unknown_methods(define_method)
        allowed_methods = %i[create_table change_table add_column remove_column drop_table]

        unknown_methods = define_method - allowed_methods
        unknown_methods.each do |method|
          ActiveRecord::Migration.prepend(Module.new do
            define_method(method) do |*args, **options|
              puts "Ignoring unknown method: #{method}"
            end
          end)
        end
      end
  end
end
