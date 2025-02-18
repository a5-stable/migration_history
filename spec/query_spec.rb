# spec/query_test.rb
# frozen_string_literal: true

require "spec_helper"
require "active_record"

RSpec.describe "QueryMethods" do
  before do
    MigrationHistory.migration_file_dir = "spec/migrations"
  end

  describe ".filter" do
    it "returns migration history for table created" do
      expect(MigrationHistory.filter("users")).to be_a(MigrationHistory::ResultSet)
    end

    it "filters migration history correctly" do
      user_filter = MigrationHistory.filter("users")
      expect(user_filter.original_result.values[0][:timestamp]).to eq 20250110010100

      user_name_filter = MigrationHistory.filter("users", "name")
      expect(user_name_filter.original_result.values[0][:timestamp]).to eq 20250110010100

      user_birthday_filter = MigrationHistory.filter("users", "birthday")
      expect(user_birthday_filter.original_result.values[0][:timestamp]).to eq 20250113010102

      user_create_table_filter = MigrationHistory.filter("users", nil, :create_table)
      expect(user_create_table_filter.original_result.values[0][:timestamp]).to eq 20250110010100
    end
  end

  describe ".all" do
    it "returns all migration history" do
      expect(MigrationHistory.all).to be_a(MigrationHistory::ResultSet)
    end
  end
end
