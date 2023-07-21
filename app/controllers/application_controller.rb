class ApplicationController < ActionController::Base
  before_action :require_login
  protect_from_forgery prepend: true
  def require_login
    Rails.logger.info "---- ApplicationController#require_login #{request&.subdomain} ----"
    return if current_user.present?
    Rails.logger.info 'You need to login first.'
    redirect_to_login(alert: 'Need to login first.') and return true
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id].present?
  rescue
    reset_session
    redirect_to_login(alert: 'Please re-login.') and return true
  end
  helper_method :current_user

  def redirect_to_login(alert: nil)
    Rails.logger.info "---- ApplicationController#redirect_to_login #{request&.subdomain} ----"
    redirect_to(new_session_path, subdomain: "login", allow_other_host: true, alert: alert)
  end
end 
