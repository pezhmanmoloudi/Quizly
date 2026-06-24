# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "flashcard_audio_service", to: "flashcard_audio_service.js"
pin "flashcard_playback_service", to: "flashcard_playback_service.js"
pin "flashcard_engine", to: "flashcard_engine.js"
