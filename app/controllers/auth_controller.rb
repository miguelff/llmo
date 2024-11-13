class AuthController < ApplicationController
    def logout
        session[:user_id] = nil
        redirect_to root_path
    end

    def daniel
        binding.pry
        session[:user_id] = User.daniel.id
        redirect_to root_path
    end

    def miguel
        session[:user_id] = User.miguel.id
        redirect_to root_path
    end
end
