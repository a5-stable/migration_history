# frozen_string_literal: true

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
      methods = {}
      ActiveRecord::Migration.prepend(MethodOverrides)

      migration_files.map do |file|
        # ファイル内で定義されているクラス名を抽出
        require file
        result = extract_migration_methods(file)
        puts "Processing: #{result}"
        class_name = result[:class_name]
        methods[class_name] = result[:methods]

        migration_histories[class_name] = {
          timestamp: File.basename(file).split("_").first.to_i,
          class_name: class_name,
          migration_file_name: file.split("/").last,
          actions: []
        }
      rescue => e
        puts "Error: #{e.message}"
      end

      migration_classes = migration_histories.keys

      migration_classes.each do |migration_class|
        migration_histories[migration_class] ||= {}
        ignore_unknown_methods(methods[migration_class])

        result = Object.const_get(migration_class).new.exec_migration(nil, :up)

        next unless result

        if result.is_a?(Array)
          migration_histories[migration_class][:actions] += result
        else
          migration_histories[migration_class][:actions] << result
        end
      end

      migration_histories.each do |migration_class, migration_info|
        migration_histories[migration_class][:git_commit] = last_commit_for_file(migration_info[:file_path])
        migration_histories[migration_class][:git_branch] = branch_for_commit(migration_histories[migration_class][:git_branch])
      end

      @migration_info = migration_histories

      nil
    end

    private
      # 対象ファイルの最後のコミットハッシュを取得する
      def last_commit_for_file(file_path)
        commit = `git log -1 --pretty=format:%H -- #{file_path}`.strip
        commit.empty? ? "unknown_commit" : commit
      rescue StandardError => e
        "error_fetching_commit: #{e.message}"
      end

      # 対象のコミットが属しているブランチ名を取得する
      def branch_for_commit(commit_hash)
        branch = `git name-rev --name-only #{commit_hash}`.strip
        branch.empty? ? "unknown_branch" : branch
      rescue StandardError => e
        "error_fetching_branch: #{e.message}"
      end
  end
end

module MigrationHistory
  module MethodOverrides
    class DummyConnectionPool
      def supports_datetime_with_precision?
        false
      end

      def method_missing(*args); end
    end

    def create_table(table_name, **options)
      results = []
      columns = []
      dummy_conn = DummyConnectionPool.new

      table_definition = ActiveRecord::ConnectionAdapters::TableDefinition.new(dummy_conn, table_name)
      table_definition.singleton_class.prepend(Module.new do
        define_method(:column) do |name, type, **options|
          columns << { name: name, type: type, options: options }
        end

        define_method(:method_missing) do |method_name, *args, **options|
          args.each { |name| column(name, :method_name, **options) }
        end
      end)
      yield(table_definition) if block_given?

      results << record_migration_action(:create_table, table_name: table_name, options: options)
      columns.each do |column|
        results << record_migration_action(:add_column_with_create_table, table_name: table_name, column_name: column[:name], type: column[:type], options: column[:options])
      end

      results
    end

    def change_table(table_name, **options)
      results = []
      columns = []
      dummy_conn = DummyConnectionPool.new
      table_definition = ActiveRecord::ConnectionAdapters::TableDefinition.new(dummy_conn, table_name)
      table_definition.singleton_class.prepend(Module.new do
        define_method(:column) do |name, type, **options|
          columns << { name: name, type: type, options: options }
        end
      end)
      yield(table_definition)

      columns.each do |column|
        results << record_migration_action(:add_column, table_name: table_name, column_name: column[:name], type: column[:type], options: column[:options])
      end

      results
    end

    def add_column(table_name, column_name, type, **options)
      record_migration_action(:add_column, table_name: table_name, column_name: column_name, type: type, options: options)
    end

    def remove_column(table_name, column_name, **options)
      record_migration_action(:remove_column, table_name: table_name, column_name: column_name, options: options)
    end

    def drop_table(table_name, **options)
      record_migration_action(:drop_table, table_name: table_name, options: options)
    end

    def method_missing(method_name, *args, **options)
    end

    private
      def record_migration_action(action, details)
        migration_info = {
          action: action,
          details: details,
        }

        migration_info
      end
  end
end

require 'parser/current'

class MigrationMethodExtractor < Parser::AST::Processor
  attr_reader :methods, :current_class

  def initialize
    @methods = []
    @current_class = nil
  end

  def on_class(node)
    class_name, _superclass, body = *node
    @current_class = class_name.children.last.to_s
    process(body)
  end

  def on_send(node)
    method_name = node.children[1]
    if @current_class
      @methods <<  method_name
    end
    super
  end
end

def extract_migration_methods(file_path)
  code = File.read(file_path)
  ast = Parser::CurrentRuby.parse(code)

  extractor = MigrationMethodExtractor.new
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
