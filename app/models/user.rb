class User < ApplicationRecord
  has_secure_password
  has_many :organisation_users
  has_many :organisations, through: :organisation_users
end
