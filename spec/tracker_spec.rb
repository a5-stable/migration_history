# frozen_string_literal: true

require "spec_helper"
require "migration_history/tracker"
require "active_record"

RSpec.describe MigrationHistory::Tracker do
  let(:tracker) { MigrationHistory::Tracker.new("spec/migrations") }

  describe "#initialize" do
    it "sets default migration_file_dir" do
      expect(tracker.migration_file_dir).to eq("spec/migrations")
    end

    it "initializes migration_info as an empty array" do
      expect(tracker.migration_info).to eq([])
    end
  end

  describe "#setup!" do
    it "sets up migration histories" do
      tracker.setup!
      expect(tracker.migration_info).not_to be_empty
    end
  end

  describe "create_table_history" do
    it "collects a create_table history" do
      tracker.setup!

      create_table_history = tracker.migration_info["CreateUsers"]
      expect(create_table_history[:class_name]).to eq("CreateUsers")

      # create_table action
      expect(create_table_history[:actions].first[:action]).to eq(:create_table)

      expected_actions = [
        { action: :create_table, details: { table_name: :users, options: {} } },
        { action: :add_column_with_create_table, details: { table_name: :users, column_name: :id, type: :method_name, options: {} } },
        { action: :add_column_with_create_table, details: { table_name: :users, column_name: :name, type: :string, options: {} } },
        { action: :add_column_with_create_table, details: { table_name: :users, column_name: :email, type: :string, options: {} } },
        { action: :add_column_with_create_table, details: { table_name: :users, column_name: :created_at, type: :datetime, options: { null: false } } },
        { action: :add_column_with_create_table, details: { table_name: :users, column_name: :updated_at, type: :datetime, options: { null: false } } }
      ]
      expect(create_table_history[:actions]).to eq(expected_actions)
    end
  end

  describe "add_column_history" do
    it "collects an add_column history" do
      tracker.setup!

      add_column_history = tracker.migration_info["AddAgeToUsers"]
      expect(add_column_history[:class_name]).to eq("AddAgeToUsers")

      # add_column action
      expect(add_column_history[:actions].first[:action]).to eq(:add_column)

      expected_actions = [
        { action: :add_column, details: { table_name: :users, column_name: :age, type: :integer, options: {} } }
      ]
      expect(add_column_history[:actions]).to eq(expected_actions)
    end
  end

  describe "change_table_history" do
    it "collects a change_table history" do
      tracker.setup!

      change_table_history = tracker.migration_info["AddColumnsToUsers"]
      expect(change_table_history[:class_name]).to eq("AddColumnsToUsers")

      expected_actions = [
        { action: :add_column, details: { table_name: :users, column_name: :birthday, type: :date, options: {} } },
        { action: :add_column, details: { table_name: :users, column_name: :phone_number, type: :string, options: {} } }
      ]
      expect(change_table_history[:actions]).to eq(expected_actions)
    end
  end

  describe "ignore unknown migration method" do
    it "ignores unknown migration method" do
      tracker.setup!

      migration_history = tracker.migration_info["AddColumnsToUsersWithUnsupportedMethod"]
      expect(migration_history[:actions].first[:action]).to eq(:add_column)
      expect(migration_history[:actions].first[:details][:column_name]).to eq(:website)
      expect(migration_history[:actions].size).to eq(1)
    end
  end
end
