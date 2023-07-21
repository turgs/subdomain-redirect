To start run, 

```bash
cp README.md README.bak.md
chmod +x script/user-setup.sh
docker-compose run --rm web bundle install
docker-compose run --rm web bundle exec rails new . --force
docker-compose up
```


To preconsifure with a user etc, run the following in a separate terminal:

```bash
bash script/user-setup.sh
```

To add subdomains per org

1. Login at login.lvh.me:3000
2. They get redirected to their subdomain on login
  - edit `app/controllers/sessions_controller.rb#create` to change this
    ```
    redirect_to user_url(user)
    to 
    redirect_to user_url(user, subdomain: user.organisations.first.subdomain), allow_other_host: true
    ```

  - edit `app/controllers/sessions_controller.rb#destroy` to change this
    ```
    redirect_to new_session_path
    to 
    redirect_to new_session_url(subdomain: "login"), allow_other_host: true
    ```

  - edit `app/controllers/application_controller.rb#current_user` to change this
    ```
    redirect_to(new_session_url, allow_other_host: true, alert: 'Please re-login.') and return true
    to 
    redirect_to(new_session_url, subdomain: "login", allow_other_host: true, alert: 'Please re-login.') and return true
    ```
  
3. This will then likely not log you in, cos the session is different for each subdomain.

For all logins to only be at the login subdomain

app/controllers/sessions_controller.rb#new
  def new
    if request&.subdomain != "login"
      redirect_to new_session_url(subdomain: "login"), allow_other_host: true, flash: flash and return
    end
  end



It DOES redirect, but says 
web_1    | Redirected to http://example.lvh.me:3000/users/1
web_1    | Completed 302 Found in 393ms (ActiveRecord: 4.9ms | Allocations: 20921)
web_1    | 
web_1    | 
web_1    | Started OPTIONS "/users/1" for 172.19.0.1 at 2023-07-21 02:19:58 +0000
web_1    |   
web_1    | ActionController::RoutingError (No route matches [OPTIONS] "/users/1"):


