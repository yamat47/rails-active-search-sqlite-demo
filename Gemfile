source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3", ">= 8.1.3.1", group: [ :default, :wasm ]
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft", group: [ :default, :wasm ]
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails", group: [ :default, :wasm ]
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", group: [ :default, :wasm ]
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails", group: [ :default, :wasm ]

# Active Search, with its SQLite FTS5 store adapter [https://github.com/basecamp/rails-active_search]
gem "rails-active_search", "~> 0.1", group: [ :default, :wasm ]
# Packs the application into a Wasm module and provides the sqlite3_wasm adapter it runs on in the browser
gem "wasmify-rails", "~> 0.5", group: [ :default, :wasm ]

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :wasm do
  gem "tzinfo-data"
end
