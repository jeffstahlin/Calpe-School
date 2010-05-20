# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_calpe_session',
  :secret      => 'b21a51985011f60225af569d2b14a4c60c050fdbc3a778c672aabd2bf0e7a2c8e04c90dc9009609bc8ce0b77b0c0f2bc59613ff4ab443962968e6bfb48881b58'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
