class User < ApplicationRecord
  has_many :reports

  def anonymous?
    self.email == "anonymous@llmo.fly.dev"
  end

  def self.anonymous
    User.find_or_create_by(name: "Anonymous", email: "anonymous@llmo.fly.dev", avatar: "users/anonymous.png")
  end

  def self.miguel
    User.find_or_create_by(name: "Miguel Fernández", email: "miguel@llmo.fly.dev", avatar: "users/miguel.png")
  end

  def self.daniel
    User.find_or_create_by(name: "Daniel Espejo", email: "daniel@llmo.fly.dev", avatar: "users/daniel.png")
  end
end
