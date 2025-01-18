class AddColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.date :birthday
      t.string :phone_number
    end
  end
end
