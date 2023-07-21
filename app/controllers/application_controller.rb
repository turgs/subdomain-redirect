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
    redirect_to(new_session_url, subdomain: "login", allow_other_host: true, alert: 'Please re-login.') and return true
  end
  helper_method :current_user
end 
