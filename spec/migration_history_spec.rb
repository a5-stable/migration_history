begin
# spec/migration_tracker_spec.rb
require_relative "../lib/migration_history"
require "spec_helper"
require "active_record"
require "active_support/dependencies"
require "active_support/logger"
require "active_support/core_ext/kernel/reporting"
require "active_support/core_ext/kernel/singleton_class"
require "active_record/tasks/database_tasks"

RSpec.describe MigrationHistory do
  before(:all) do
    # マイグレーションファイルを読み込み
    
    class NullConnection
      def extend(_module)
        # extendの呼び出しをモック化
        puts "Extended with #{_module}"
      end
    end
    
    # テスト環境でのActiveRecord::Base.connectionをモック
    ActiveRecord::Base.singleton_class.class_eval do
      def connection
        @null_connection ||= NullConnection.new
      end
    end

    MigrationHistory::Tracker.new.setup!  
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table(:users, if_exists: true)
  end

  describe ".setup!" do
    it "executes migrations and tracks changes" do
      # テスト用にsetup!を実行
      allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:migrate)
      described_class.setup!

      # ActiveRecord::Tasks::DatabaseTasks.migrateが呼ばれたことを確認
      expect(ActiveRecord::Tasks::DatabaseTasks).to have_received(:migrate)

      # 実際にテーブルが作成されたことを確認
      expect(ActiveRecord::Base.connection.table_exists?(:users)).to be(true)
    end
  end
end
rescue => e
  binding.irb
end
