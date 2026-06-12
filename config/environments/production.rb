require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Security headers — X-Frame-Options and X-Content-Type-Options are Rails defaults,
  # listed explicitly here so they are visible and not accidentally overridden.
  config.action_dispatch.default_headers = {
    "X-Frame-Options"        => "SAMEORIGIN",
    "X-Content-Type-Options" => "nosniff",
    "Referrer-Policy"        => "strict-origin-when-cross-origin"
  }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Raise delivery errors so failed jobs are recorded in solid_queue_failed_executions
  # and retried by ApplicationJob#retry_on rather than silently discarded.
  config.action_mailer.raise_delivery_errors = true

  # Set host to be used by links generated in mailer templates.
  # Raises KeyError at boot if unset — prevents silent misconfiguration.
  config.action_mailer.default_url_options = { host: ENV.fetch("MAILER_HOST") }

  # SendGrid SMTP relay. Credentials stored in config/credentials.yml.enc under smtp.sendgrid_api_key.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name:            "apikey",
    password:             Rails.application.credentials.dig(:smtp, :sendgrid_api_key),
    address:              "smtp.sendgrid.net",
    port:                 587,
    authentication:       :plain,
    enable_starttls_auto: true
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # REQUIRED before launch: uncomment and set your production domain to prevent
  # DNS rebinding attacks and Host-header injection.
  # config.hosts = [
  #   ENV.fetch("APP_HOST"),
  #   /.*\.#{Regexp.escape(ENV.fetch("APP_HOST", ""))}$/
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
