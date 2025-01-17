module MigrationHistory
  class Tracker
    attr_accessor :info
    def initialize
      info = []
    end

    def setup!(history  = nil)
      migration_path = File.expand_path("../spec/migrations", __dir__)
      migration_files = Dir.glob(File.join(migration_path, "*.rb"))

      datetime_and_class_mapping = {}
      migration_files.map do |file|
        # ファイルを読み込む
        require file
      
        # ファイル内で定義されているクラス名を抽出
        class_name = nil
        File.readlines(file).each do |line|
          if line.strip.start_with?('class ')
            class_name = line.strip.split(' ')[1]
            break
          end
        end
      
        datetime_and_class_mapping[class_name] = file if class_name && Object.const_defined?(class_name)
      end

      migration_classes = datetime_and_class_mapping.keys

      ActiveRecord::Migration::Compatibility::V5_2.prepend(MethodOverrides)
      migration_classes.each do |migration_class|
        Object.const_get(migration_class).new.exec_migration(nil, :up)
      end
    end
  end

  module MethodOverrides
    def create_table(table_name, **options)
      record_migration_action(:create_table, table_name: table_name, options: options)
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

    private

    def record_migration_action(action, details)
      migration_info = {
        action: action,
        details: details,
        timestamp: Time.now,
        git_branch: `git rev-parse --abbrev-ref HEAD`.strip,
        git_commit: `git rev-parse HEAD`.strip
      }
      # インスタンスのmigration_infoに保存
      @history.migration_info << migration_info
      puts "Recorded Migration Action: #{migration_info.inspect}"
    end
  end
end

# module MigrationHistory
#   include MigrationTracker
#   attr_accessor :migration_info

#   def initialize
#     @migration_info = [] # migration_infoをインスタンス変数として初期化
#   end

#   def setup!
#     MigrationTracker.setup!(self)
#   end
# end
