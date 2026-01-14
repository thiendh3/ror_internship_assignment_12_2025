# Pin npm packages by running ./bin/importmap

pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.0.0/lib/assets/compiled/rails-ujs.js"
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "search_autocomplete", to: "search_autocomplete.js"
pin "micropost_ajax", to: "micropost_ajax.js"
