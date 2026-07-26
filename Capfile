# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# Explicit Git SCM plugin (suppresses deprecation warning in Capistrano 3.x)
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# rbenv integration — loads Ruby via the deploy user's rbenv
require "capistrano/rbenv"

# Bundler — runs bundle install on each deploy
require "capistrano/bundler"

# Rails tasks — assets:precompile and db:migrate
require "capistrano/rails/assets"
require "capistrano/rails/migrations"

# Load any custom tasks from lib/capistrano/tasks
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
