set -xe

# uncomment bcypt in Gemfile
sed -i 's~# gem "bcrypt", "~gem "bcrypt", "~' Gemfile
docker-compose exec web bundle install

# allow webconsole in dev
sed -i 's~Rails.application.configure do~&\n  config.web_console.permissions = "0.0.0.0/0"~' config/environments/development.rb

# Scaffold to generate a User
docker-compose exec web bundle exec rails g scaffold User name:string email:string password_digest:string

# Scaffold to generate an Organisation
docker-compose exec web bundle exec rails g scaffold Organisation name:string subdomain:string creator:string

# Generate join table for Organisation and User
docker-compose exec web bundle exec rails g model OrganisationUser user:references organisation:references

# run migrations
docker-compose exec web bundle exec rails db:migrate


# add session#new controller
docker-compose exec web bundle exec rails g scaffold Session
sleep 1
rm -rf app/views/sessions app/helpers/sessions_helper.rb test/models/session_test.rb test/fixtures/sessions.yml db/migrate/*_create_sessions.rb app/models/session.rb

cat <<EOF > app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :require_login
  
  def new
  end

  def create
    user = User.find_by_email(params[:email].downcase)

    if user.blank?
      redirect_to(new_session_path, alert: %{Email <span class="font-mono">#{params[:email]}</span> not found. Maybe you mistyped it, or used a different email address?}, flash: {html_safe: true}) and return
    end

    if !user.authenticate(params[:password])
      redirect_to(new_session_path, alert: "Password is incorrect. Maybe you mistyped it, or changed it?") and return
    end

    reset_session
    session[:user_id] = user.id

    redirect_to user_url(user), allow_other_host: true
  end

  def destroy
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_to new_session_path
  end
end
EOF

# Add require_login before_action in ApplicationController
cat <<EOF > app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :require_login
  def require_login
    return if current_user.present?
    redirect_to(new_session_path, alert: 'Need to login first.') and return true
  end
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id].present?
  rescue
    reset_session
    redirect_to(new_session_url, allow_other_host: true, alert: 'Please re-login.') and return true
  end
  helper_method :current_user
end 
EOF

# Add has_secure_password in User model
cat <<EOF > app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_many :organisation_users
  has_many :organisations, through: :organisation_users
end
EOF

cat <<EOF > app/models/organisation.rb
class Organisation < ApplicationRecord
  has_many :organisation_users
  has_many :users, through: :organisation_users
end
EOF

cat <<EOF >> app/views/users/show.html.erb

<p>Organisations:</p>
<% @user.organisations.each do |org| %>
  <%= link_to org.name, org %>
<% end %>
EOF

# Add config.hosts << "lvh.me" to config/application.rb on a new line immediately following class Application < Rails::Application
sed -i 's~class Application < Rails::Application~&\n    config.hosts << ".lvh.me"~' config/application.rb

# Add logged in header to layout on new line immediately following <body>: 
# <% if current_user.present? %>Logged in <%= current_user.name %> (<%= link_to 'Logout', session_path(current_user), method: :delete %>)<% end %>
sed -i 's~<body>~&\n    <% if current_user.present? %>Logged in <%= current_user.name %> <%= button_to "Logout", session_path(current_user), method: :delete, form: {style: "display:inline"} %><hr/><% end %>\n    <% flash.each do |key, value| %><div><%= value %></div><% end %>' app/views/layouts/application.html.erb

# create seed default data
docker-compose exec web bundle exec rails runner "org = Organisation.create!(name: 'Example Organisation', subdomain: 'example', creator: 'example'); user = User.create!(name: 'Jo Citizen', email: 'user@example.com', password: 'user@example.com'); OrganisationUser.create!(user: user, organisation: org)"

docker-compose stop

echo 
echo "--- Finished ---"
echo "You need to rerun 'docker-compse up' now in your other terminal window."
echo