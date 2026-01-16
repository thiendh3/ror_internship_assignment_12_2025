# Pin npm packages by running ./bin/importmap

pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.0.0/lib/assets/compiled/rails-ujs.js"
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "channels/consumer", to: "channels/consumer.js"
pin "channels/notifications_channel", to: "channels/notifications_channel.js"
pin "channels/microposts_channel", to: "channels/microposts_channel.js"
pin "microposts", to: "microposts.js"
pin "users", to: "users.js"
pin "social", to: "social.js"
pin "follow", to: "follow.js"
