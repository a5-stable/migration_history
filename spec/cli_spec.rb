require "spec_helper"
require "migration_history/cli"
require "thor"

RSpec.describe MigrationHistory::CLI do
  let(:cli) { MigrationHistory::CLI.new }
  before do
    MigrationHistory.migration_file_dir = "spec/migrations"
  end

  describe "#filter" do
    it "filters migration history and prints to console" do
      # bundle exec migration_history filter --table users --column name
      expect { cli.invoke(:filter, [], table: "users", column: "name") }.to output(/ClassName: CreateUsers, Timestamp: 20250110010100/).to_stdout
    end

    it "filters migration history and generates HTML" do
      # bundle exec migration_history filter --table users --column name --output=output.html
      expect { cli.invoke(:filter, [], table: "users", column: "name", output: "output.html").to output(/output to output.html/).to_stdout }
    end
  end

  describe "#all" do
    it "retrieves all migration history and prints to console" do
      expect { cli.invoke(:all) }.to output(/ClassName: CreateUsers, Timestamp: 20250110010100/).to_stdout
    end

    it "retrieves all migration history and generates HTML" do
      expect { cli.invoke(:all).to output(/output to output.html/).to_stdout }
    end
  end
end
