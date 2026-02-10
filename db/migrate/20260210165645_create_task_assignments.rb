class CreateTaskAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :task_assignments do |t|
      t.references :task, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.datetime :assigned_at

      t.timestamps
    end

    add_index :task_assignments, [:task_id, :member_id], unique: true
  end
end

