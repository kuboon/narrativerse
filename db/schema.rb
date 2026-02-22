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

ActiveRecord::Schema[8.0].define(version: 2026_02_21_000008) do
  create_table "element_revisions", force: :cascade do |t|
    t.integer "element_id", null: false
    t.integer "user_id", null: false
    t.integer "revision", null: false
    t.text "summary"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["element_id", "revision"], name: "index_element_revisions_on_element_id_and_revision", unique: true
    t.index ["element_id"], name: "index_element_revisions_on_element_id"
    t.index ["user_id"], name: "index_element_revisions_on_user_id"
  end

  create_table "elements", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "element_type", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["element_type"], name: "index_elements_on_element_type"
    t.index ["user_id"], name: "index_elements_on_user_id"
  end

  create_table "plot_elements", force: :cascade do |t|
    t.integer "plot_id", null: false
    t.integer "element_id", null: false
    t.integer "element_revision_id", null: false
    t.text "summary"
    t.text "secrets"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["element_id"], name: "index_plot_elements_on_element_id"
    t.index ["element_revision_id"], name: "index_plot_elements_on_element_revision_id"
    t.index ["plot_id"], name: "index_plot_elements_on_plot_id"
  end

  create_table "plot_parent_links", force: :cascade do |t|
    t.integer "child_plot_id", null: false
    t.integer "parent_plot_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_plot_id", "parent_plot_id"], name: "index_plot_parents_on_child_and_parent", unique: true
    t.index ["child_plot_id"], name: "index_plot_parent_links_on_child_plot_id"
    t.index ["parent_plot_id"], name: "index_plot_parent_links_on_parent_plot_id"
  end

  create_table "plot_scene_links", force: :cascade do |t|
    t.integer "plot_id", null: false
    t.integer "scene_id", null: false
    t.integer "next_scene_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["next_scene_id"], name: "index_plot_scene_links_on_next_scene_id"
    t.index ["plot_id", "scene_id"], name: "index_plot_scene_links_on_plot_id_and_scene_id", unique: true
    t.index ["plot_id"], name: "index_plot_scene_links_on_plot_id"
    t.index ["scene_id"], name: "index_plot_scene_links_on_scene_id"
  end

  create_table "plots", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.text "summary"
    t.integer "scene_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scene_id"], name: "index_plots_on_scene_id"
    t.index ["user_id"], name: "index_plots_on_user_id"
  end

  create_table "scenes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_scenes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "icon"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "element_revisions", "elements"
  add_foreign_key "element_revisions", "users"
  add_foreign_key "elements", "users"
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
end
