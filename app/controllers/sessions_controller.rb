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

    redirect_to user_url(subdomain: user.org.subdomain), allow_other_host: true
  end

  def destroy
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_to new_session_url(subdomain: "login"), allow_other_host: true
  end
end
