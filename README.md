# README

## How to run this app

Everything is within docker-compose, so you need Docker!

You'll first need to run the first-time setups, to create the docker container and the seed data:

```bash
docker-compose build
docker-compose run --rm web bundle install
docker-compose run --rm web bundle exec rails runner "org = Organisation.create!(name: 'Example Organisation', subdomain: 'example', creator: 'example'); user = User.create!(name: 'Jo Citizen', email: 'user@example.com', password: 'user@example.com'); OrganisationUser.create!(user: user, organisation: org)"
```

Then just:

```bash
docker-compose up
```

Navigate to [http://login.lvh.me:3000/sessions/new](http://login.lvh.me:3000/sessions/new)

Login with the sample data username/password of:

- Username: `user@example.com`
- Password: `user@example.com`

## Desired outcome

What I want is for

1. users to login at `http://login.lvh.me:3000/sessions/new` (note, the subdomain `login`)
2. once they're authenticated, they get redirected to their subdomain, e.g. `http://my-org.lvh.me:3000/`.

## Problem

I'm missing something in my implementation, because, I can see that the authentication is successful, and the app log shows it's redirecting to "http://example.lvh.me:3000/users/1", but then when that controller loads, the session must be different, because the app thinks the user isn't logged in.

I _have_ alread set:

- _config/application.rb_ to `config.session_store :cookie_store, key: '_my_app_session', domain: :all, tld_length: 2`
- _config/application.rb_ to `config.hosts << ".lvh.me"`

I do not use Devise. I use _has_secure_password_ and a `before_action :require_login` within _ApplicationController_.

When the user submits the login form, it:

1. submits to [app/controllers/sessions_controller.rb#create](https://github.com/turgs/subdomain-redirect/blob/master/app/controllers/sessions_controller.rb#L11), which then redirects `redirect_to user_url(user, subdomain: user.organisations.first.subdomain), allow_other_host: true`

2. That then loads the show action in the Users controller, which calls the ApplicationController before_action [require_login](https://github.com/turgs/subdomain-redirect/blob/master/app/controllers/application_controller.rb#L4-L9).

3. At that point it doesn't think the session is set, so it redirects to the login page. :(