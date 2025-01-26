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
  end

  describe ".all" do
    it "returns all migration history" do
      expect(MigrationHistory.all).to be_a(MigrationHistory::ResultSet)
    end
  end
end
