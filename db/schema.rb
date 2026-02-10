# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_02_11_120200) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_graphql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "supabase_vault"
  enable_extension "uuid-ossp"

  create_table "help_answers", force: :cascade do |t|
    t.bigint "help_request_id", null: false
    t.bigint "admin_id", null: false
    t.text "answer", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_help_answers_on_admin_id"
    t.index ["help_request_id"], name: "index_help_answers_on_help_request_id", unique: true
  end

  create_table "help_requests", force: :cascade do |t|
    t.bigint "requester_id", null: false
    t.bigint "admin_id", null: false
    t.text "question", null: false
    t.string "status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_help_requests_on_admin_id"
    t.index ["requester_id"], name: "index_help_requests_on_requester_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_members_on_email", unique: true
    t.index ["role_id"], name: "index_members_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "task_assignments", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "member_id", null: false
    t.datetime "assigned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at"
    t.text "completion_comment"
    t.index ["member_id"], name: "index_task_assignments_on_member_id"
    t.index ["task_id", "member_id"], name: "index_task_assignments_on_task_id_and_member_id", unique: true
    t.index ["task_id"], name: "index_task_assignments_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "pending", null: false
    t.string "priority"
    t.date "due_date"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_tasks_on_created_by_id"
  end

  add_foreign_key "help_answers", "help_requests"
  add_foreign_key "help_answers", "members", column: "admin_id"
  add_foreign_key "help_requests", "members", column: "admin_id"
  add_foreign_key "help_requests", "members", column: "requester_id"
  add_foreign_key "members", "roles"
  add_foreign_key "task_assignments", "members"
  add_foreign_key "task_assignments", "tasks"
  add_foreign_key "tasks", "members", column: "created_by_id"
end
