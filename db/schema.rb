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

ActiveRecord::Schema[8.1].define(version: 2026_02_28_101850) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "model_id"
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_chats_on_model_id"
  end

  create_table "element_revisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "element_id", null: false
    t.integer "revision", null: false
    t.text "summary"
    t.text "text"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["element_id", "revision"], name: "index_element_revisions_on_element_id_and_revision", unique: true
    t.index ["element_id"], name: "index_element_revisions_on_element_id"
    t.index ["user_id"], name: "index_element_revisions_on_user_id"
  end

  create_table "elements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "element_type", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["element_type"], name: "index_elements_on_element_type"
    t.index ["user_id"], name: "index_elements_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.integer "chat_id", null: false
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.integer "model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.text "thinking_signature"
    t.text "thinking_text"
    t.integer "thinking_tokens"
    t.integer "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["model_id"], name: "index_messages_on_model_id"
    t.index ["role"], name: "index_messages_on_role"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
  end

  create_table "models", force: :cascade do |t|
    t.json "capabilities", default: []
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.json "metadata", default: {}
    t.json "modalities", default: {}
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.json "pricing", default: {}
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["family"], name: "index_models_on_family"
    t.index ["provider", "model_id"], name: "index_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_models_on_provider"
  end

  create_table "plot_elements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "element_id", null: false
    t.integer "element_revision_id", null: false
    t.integer "plot_id", null: false
    t.text "secrets"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["element_id"], name: "index_plot_elements_on_element_id"
    t.index ["element_revision_id"], name: "index_plot_elements_on_element_revision_id"
    t.index ["plot_id", "element_id"], name: "index_plot_elements_on_plot_id_and_element_id", unique: true
    t.index ["plot_id"], name: "index_plot_elements_on_plot_id"
  end

  create_table "plot_parent_links", force: :cascade do |t|
    t.integer "child_plot_id", null: false
    t.datetime "created_at", null: false
    t.integer "parent_plot_id", null: false
    t.datetime "updated_at", null: false
    t.index ["child_plot_id", "parent_plot_id"], name: "index_plot_parents_on_child_and_parent", unique: true
    t.index ["child_plot_id"], name: "index_plot_parent_links_on_child_plot_id"
    t.index ["parent_plot_id"], name: "index_plot_parent_links_on_parent_plot_id"
  end

  create_table "plot_scene_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "next_scene_id"
    t.integer "plot_id", null: false
    t.integer "scene_id", null: false
    t.datetime "updated_at", null: false
    t.index ["next_scene_id"], name: "index_plot_scene_links_on_next_scene_id"
    t.index ["plot_id", "scene_id"], name: "index_plot_scene_links_on_plot_id_and_scene_id", unique: true
    t.index ["plot_id"], name: "index_plot_scene_links_on_plot_id"
    t.index ["scene_id"], name: "index_plot_scene_links_on_scene_id"
  end

  create_table "plots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "scene_id", null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["scene_id"], name: "index_plots_on_scene_id"
    t.index ["user_id"], name: "index_plots_on_user_id"
  end

  create_table "scenes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_scenes_on_user_id"
  end

  create_table "tool_calls", force: :cascade do |t|
    t.json "arguments", default: {}
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.string "name", null: false
    t.string "thought_signature"
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["name"], name: "index_tool_calls_on_name"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chats", "models"
  add_foreign_key "element_revisions", "elements"
  add_foreign_key "element_revisions", "users"
  add_foreign_key "elements", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "models"
  add_foreign_key "messages", "tool_calls"
  add_foreign_key "plot_elements", "element_revisions"
  add_foreign_key "plot_elements", "elements"
  add_foreign_key "plot_elements", "plots"
  add_foreign_key "plot_parent_links", "plots", column: "child_plot_id"
  add_foreign_key "plot_parent_links", "plots", column: "parent_plot_id"
  add_foreign_key "plot_scene_links", "plots"
  add_foreign_key "plot_scene_links", "scenes"
  add_foreign_key "plot_scene_links", "scenes", column: "next_scene_id"
  add_foreign_key "plots", "scenes"
  add_foreign_key "plots", "users"
  add_foreign_key "scenes", "users"
  add_foreign_key "tool_calls", "messages"
end
