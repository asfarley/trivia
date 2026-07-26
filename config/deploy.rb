set :application, "trivia"
set :repo_url,    "git@github.com:asfarley/trivia.git"
set :branch,      :main
set :deploy_to,   "/home/deploy/apps/trivia"

# rbenv — Ruby is installed per-user under /home/deploy/.rbenv
set :rbenv_type,  :user
set :rbenv_ruby,  "3.4.2"
set :rbenv_path,  "/home/deploy/.rbenv"

# Dirs that persist across releases (Capistrano symlinks these into current/)
append :linked_dirs,
  "storage",        # all four SQLite databases
  "log",
  "tmp/pids",
  "tmp/cache",
  "tmp/sockets",    # puma.sock lives here
  "public/system"

# Keep the last 5 releases on the server
set :keep_releases, 5

# Assets don't need real credentials — pass a dummy secret_key_base so
# precompilation works without RAILS_MASTER_KEY in the deploy shell.
# set :default_env merges into SSHKit's `with` block for every remote command.
set :default_env, { "SECRET_KEY_BASE_DUMMY" => "1" }

# SSH via the project's credentials key; forward the local ssh-agent so
# Capistrano can clone from GitHub without a server-side deploy key.
set :ssh_options, {
  forward_agent:   true,
  auth_methods:    ["publickey"],
  verify_host_key: :never        # skip host key verification (single-dev, private EC2)
}

# After publishing a new release, restart Puma via systemd.
# The deploy user has passwordless sudo for systemctl puma commands
# (configured by the Ansible sudoers role).
namespace :deploy do
  after :publishing, :restart do
    on roles(:web), in: :sequence, wait: 5 do
      execute :sudo, "/bin/systemctl restart puma"
    end
  end
end
