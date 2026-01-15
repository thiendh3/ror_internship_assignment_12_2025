// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import Rails from "@rails/ujs"
import "search_autocomplete"
import "micropost_ajax"
import "micropost_likes"
import "notifications"
import "comments"
import "share"
import "micropost_realtime"
Rails.start()
