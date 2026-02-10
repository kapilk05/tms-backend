class CreateMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :members do |t|
      t.string :email, null: false
      t.string :password, null: false
      t.string :name, null: false
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end

    add_index :members, :email, unique: true
  end
end