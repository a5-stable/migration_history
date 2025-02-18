# frozen_string_literal: true

class AddColumnsToUsersWithUnsupportedMethod < ActiveRecord::Migration[6.1]
  def change
    # Assume that this migration file is created by a third-party gem
    # we cannot support add_special_column method, so should be ignored
    add_special_column :users, :auth_token, :string

    # We can support add_column method
    add_column :users, :website, :string

    # Rails built-in method, but we do not support add_index method right now
    add_index :users, :email, unique: true
  end
end
