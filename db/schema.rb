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

ActiveRecord::Schema[8.1].define(version: 2026_06_20_205556) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "badges", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "icon", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_badges_on_key", unique: true
  end

  create_table "card_progresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "ease_factor", default: 2.5, null: false
    t.integer "flashcard_id", null: false
    t.integer "interval", default: 1, null: false
    t.datetime "last_reviewed_at"
    t.datetime "next_review_at"
    t.integer "repetitions", default: 0, null: false
    t.boolean "starred", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["flashcard_id"], name: "index_card_progresses_on_flashcard_id"
    t.index ["next_review_at"], name: "index_card_progresses_on_next_review_at"
    t.index ["user_id", "flashcard_id"], name: "index_card_progresses_on_user_id_and_flashcard_id", unique: true
    t.index ["user_id", "next_review_at"], name: "index_card_progresses_on_user_id_and_next_review_at"
    t.index ["user_id", "starred"], name: "index_card_progresses_on_user_id_and_starred"
    t.index ["user_id"], name: "index_card_progresses_on_user_id"
  end

  create_table "deck_folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "deck_id", null: false
    t.bigint "folder_id", null: false
    t.datetime "updated_at", null: false
    t.index ["deck_id", "folder_id"], name: "index_deck_folders_on_deck_id_and_folder_id", unique: true
    t.index ["deck_id"], name: "index_deck_folders_on_deck_id"
    t.index ["folder_id"], name: "index_deck_folders_on_folder_id"
  end

  create_table "decks", force: :cascade do |t|
    t.string "access_mode", default: "open", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "draft", default: true, null: false
    t.integer "flashcards_count", default: 0, null: false
    t.string "language_code"
    t.string "name"
    t.string "password_digest"
    t.integer "source_deck_id"
    t.string "status", default: "published", null: false
    t.string "subject_tags"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "visibility", default: "public", null: false
    t.index ["access_mode"], name: "index_decks_on_access_mode"
    t.index ["draft"], name: "index_decks_on_draft"
    t.index ["source_deck_id"], name: "index_decks_on_source_deck_id"
    t.index ["status"], name: "index_decks_on_status"
    t.index ["user_id"], name: "index_decks_on_user_id"
    t.index ["visibility"], name: "index_decks_on_visibility"
  end

  create_table "flashcards", force: :cascade do |t|
    t.text "back_content", null: false
    t.string "back_language"
    t.datetime "created_at", null: false
    t.integer "deck_id", null: false
    t.datetime "deleted_at"
    t.text "front_content", null: false
    t.string "front_language"
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["deck_id"], name: "index_flashcards_on_deck_id"
    t.index ["deleted_at"], name: "index_flashcards_on_deleted_at"
    t.index ["position"], name: "index_flashcards_on_position"
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", default: "manual", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["kind"], name: "index_folders_on_kind"
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "learn_session_items", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.integer "correct_streak", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "flashcard_id", null: false
    t.bigint "learn_session_id", null: false
    t.integer "position", null: false
    t.string "status", default: "unseen", null: false
    t.datetime "updated_at", null: false
    t.index ["flashcard_id"], name: "index_learn_session_items_on_flashcard_id"
    t.index ["learn_session_id", "flashcard_id"], name: "index_learn_session_items_on_learn_session_id_and_flashcard_id", unique: true
    t.index ["learn_session_id", "position"], name: "index_learn_session_items_on_learn_session_id_and_position"
    t.index ["learn_session_id", "status"], name: "index_learn_session_items_on_learn_session_id_and_status"
    t.index ["learn_session_id"], name: "index_learn_session_items_on_learn_session_id"
  end

  create_table "learn_sessions", force: :cascade do |t|
    t.integer "cards_mastered", default: 0, null: false
    t.integer "cards_total", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "deck_id", null: false
    t.datetime "finished_at"
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deck_id"], name: "index_learn_sessions_on_deck_id"
    t.index ["user_id", "deck_id"], name: "index_learn_sessions_on_user_id_and_deck_id"
    t.index ["user_id", "started_at"], name: "index_learn_sessions_on_user_id_and_started_at"
    t.index ["user_id"], name: "index_learn_sessions_on_user_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "email_streaks_badges", default: true, null: false
    t.boolean "email_study_reminders", default: true, null: false
    t.string "reminder_time", default: "08:00", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_notification_preferences_on_user_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "actor_id"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["recipient_id", "created_at"], name: "index_notifications_on_recipient_id_and_created_at"
    t.index ["recipient_id", "read", "created_at"], name: "index_notifications_on_recipient_id_and_read_and_created_at"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "study_sessions", force: :cascade do |t|
    t.integer "cards_correct", default: 0, null: false
    t.integer "cards_reviewed", default: 0, null: false
    t.integer "cards_total", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "deck_id", null: false
    t.datetime "finished_at"
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deck_id"], name: "index_study_sessions_on_deck_id"
    t.index ["user_id", "deck_id"], name: "index_study_sessions_on_user_id_and_deck_id"
    t.index ["user_id", "started_at"], name: "index_study_sessions_on_user_id_and_started_at"
    t.index ["user_id"], name: "index_study_sessions_on_user_id"
  end

  create_table "test_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_index", default: 0, null: false
    t.bigint "deck_id", null: false
    t.datetime "finished_at"
    t.text "questions_data", null: false
    t.integer "questions_total", default: 0, null: false
    t.integer "score", default: 0, null: false
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deck_id"], name: "index_test_sessions_on_deck_id"
    t.index ["user_id", "deck_id"], name: "index_test_sessions_on_user_id_and_deck_id"
    t.index ["user_id", "started_at"], name: "index_test_sessions_on_user_id_and_started_at"
    t.index ["user_id"], name: "index_test_sessions_on_user_id"
  end

  create_table "user_badges", force: :cascade do |t|
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "earned_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["badge_id"], name: "index_user_badges_on_badge_id"
    t.index ["user_id", "badge_id"], name: "index_user_badges_on_user_id_and_badge_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_streak", default: 0, null: false
    t.string "display_name"
    t.string "email_address", null: false
    t.string "google_access_token"
    t.string "google_uid"
    t.date "last_studied_on"
    t.string "locale", default: "en", null: false
    t.integer "longest_streak", default: 0, null: false
    t.string "password_digest"
    t.boolean "show_avatar", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "card_progresses", "flashcards"
  add_foreign_key "card_progresses", "users"
  add_foreign_key "deck_folders", "decks", on_delete: :cascade
  add_foreign_key "deck_folders", "folders", on_delete: :cascade
  add_foreign_key "decks", "decks", column: "source_deck_id", on_delete: :nullify
  add_foreign_key "decks", "users"
  add_foreign_key "flashcards", "decks"
  add_foreign_key "folders", "users"
  add_foreign_key "learn_session_items", "flashcards"
  add_foreign_key "learn_session_items", "learn_sessions"
  add_foreign_key "learn_sessions", "decks"
  add_foreign_key "learn_sessions", "users"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "study_sessions", "decks"
  add_foreign_key "study_sessions", "users"
  add_foreign_key "test_sessions", "decks"
  add_foreign_key "test_sessions", "users"
  add_foreign_key "user_badges", "badges"
  add_foreign_key "user_badges", "users"
end
