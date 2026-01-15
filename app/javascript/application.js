// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "channels/notifications_channel"
import "channels/microposts_channel"
import "./microposts"
import Rails from "@rails/ujs"
Rails.start()
