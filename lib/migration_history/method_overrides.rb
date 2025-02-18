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

      @actions += results
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

      @actions += results
    end

    def add_column(table_name, column_name, type, **options)
      @actions << record_migration_action(:add_column, table_name: table_name, column_name: column_name, type: type, options: options)
    end

    def remove_column(table_name, column_name, **options)
      @actions << record_migration_action(:remove_column, table_name: table_name, column_name: column_name, options: options)
    end

    def drop_table(table_name, **options)
      @actions << record_migration_action(:drop_table, table_name: table_name, options: options)
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
