# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.uuid :id
      t.column :nickname, :string, default: "Tom"
      t.string :name
      t.string :email
      t.timestamps

      t.index :email, unique: true
    end
  end
end
