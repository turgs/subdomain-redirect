class Organisation < ApplicationRecord
  has_many :users, through: :organisation_users
end
