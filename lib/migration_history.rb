module MigrationHistory
  class InvalidError
    def initialize(message)
      @message = message
    end
  end

  def self.for_table_created(table_name)
    raise InvalidError.new("Table name is required") unless table_name
    filter(table_name, nil, action_name = "create_table")
  end

  def self.for_column_added(table_name, column_name)
    raise InvalidError.new("Table name and column name are required") unless table_name && column_name
    filter(table_name, column_name, action_name = "add_column")
  end

  def self.filter(table_name, column_name = nil, action_name = nil)
    table_name = table_name.to_s
    column_name = column_name.to_s if column_name
    action_name = action_name.to_s if action_name
    raise InvalidError.new("Table name is required") unless table_name
   
    a = Tracker.new
    a.setup!
    found_migration_info = a.migration_info.values.select do |v|
      v[:details][:table_name] == table_name &&
        (column_name.nil? || v[:details][:column_name] == column_name) &&
        (action_name.nil? || v[:action] == action_name)
    end

    found_migration_info.map do |info|
      Result.new(
        timestamp: info[:timestamp],
        git_branch: info[:git_branch],
        git_commit: info[:git_commit]
      )
    end
  end

  class Result
    attr_accessor :timestamp, :git_branch, :git_commit

    def initialize(timestamp:, git_branch:, git_commit:)
      @timestamp = timestamp
      @git_branch = git_branch
      @git_commit = git_commit
    end
  end

  class Tracker
    attr_accessor :migration_info
    def initialize
      @migration_info ||= []
    end

    def setup!(history = Tracker.new)
      migration_path = File.expand_path("../spec/migrations", __dir__)
      migration_files = Dir.glob(File.join(migration_path, "*.rb"))

      migration_histories = {}

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
        next unless class_name
     
        migration_histories[class_name] = { 
          timestamp: File.basename(file).split('_').first.to_i,
          class_name: class_name,
          file_path: file
        }
      end

      migration_classes = migration_histories.keys

      ActiveRecord::Migration::Compatibility.constants.each do |const_name|
        mod = ActiveRecord::Migration::Compatibility.const_get(const_name)
      
        # モジュールであれば `prepend` を適用
        if mod.is_a?(Module)
          mod.prepend(MethodOverrides)
        end
      end
      migration_classes.each do |migration_class|
        migration_histories[migration_class] ||= {}
        migration_histories[migration_class].merge!(Object.const_get(migration_class).new.exec_migration(nil, :up))
      end

      migration_histories.each do |migration_class, migration_info|
        migration_histories[migration_class][:git_commit] = last_commit_for_file(migration_info[:file_path])
        migration_histories[migration_class][:git_branch] = branch_for_commit(migration_histories[migration_class][:git_branch])
      end

      @migration_info = migration_histories

      nil
    end

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
      }
     
      migration_info
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
