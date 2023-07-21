class SessionsController < ApplicationController
  skip_before_action :require_login
  
  def new
    if request&.subdomain != "login"
      redirect_to new_session_url(subdomain: "login"), allow_other_host: true, flash: flash and return
    end
  end

  def create
    puts
    puts "---- SessionsController#create #{request&.subdomain} ----"
    puts

    user = User.find_by_email(params[:email].downcase)

    if user.blank?
      redirect_to_login(alert: %{Email <span class="font-mono">#{params[:email]}</span> not found. Maybe you mistyped it, or used a different email address?}, flash: {html_safe: true}) and return
    end

    if !user.authenticate(params[:password])
      redirect_to_login(alert: "Password is incorrect. Maybe you mistyped it, or changed it?") and return
    end

    reset_session
    session[:user_id] = user.id

    redirect_to user_url(user, subdomain: user.organisations.first.subdomain), allow_other_host: true
  end

  def destroy
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_to_login
  end
end
