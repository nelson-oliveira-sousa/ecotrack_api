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

ActiveRecord::Schema[8.1].define(version: 2026_04_16_204355) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "revoked_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp"
    t.string "jti"
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_revoked_tokens_on_jti"
  end

  create_table "telemetry_raw_readings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "level"
    t.jsonb "raw_payload"
    t.datetime "updated_at", null: false
    t.bigint "waste_bin_id", null: false
    t.index ["waste_bin_id"], name: "index_telemetry_raw_readings_on_waste_bin_id"
  end

  create_table "tenant_profiles", force: :cascade do |t|
    t.string "contact_email"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.string "document"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["document"], name: "index_tenant_profiles_on_document"
    t.index ["tenant_id"], name: "index_tenant_profiles_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tenants_on_code", unique: true
    t.index ["slug"], name: "index_tenants_on_slug"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.string "role"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  create_table "waste_bins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label"
    t.decimal "latitude"
    t.integer "level"
    t.decimal "longitude"
    t.string "status"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_waste_bins_on_tenant_id"
  end

  add_foreign_key "telemetry_raw_readings", "waste_bins"
  add_foreign_key "tenant_profiles", "tenants"
  add_foreign_key "users", "tenants"
  add_foreign_key "waste_bins", "tenants"
end
