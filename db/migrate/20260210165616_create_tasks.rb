class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "pending"
      t.string :priority
      t.date :due_date
      t.references :created_by, null: false, foreign_key: { to_table: :members }

      t.timestamps
    end
  end
end