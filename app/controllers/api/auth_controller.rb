# app/controllers/api/auth_controller.rb
module Api
  class AuthController < ApplicationController
    skip_before_action :authenticate_request, only: [:register, :login]

    def register
      role = Role.find_or_create_by(name: params[:role_name] || 'user')
      
      member = Member.new(
        email: params[:email],
        password: params[:password],
        name: params[:name],
        role: role
      )

      if member.save
        render json: {
          id: member.id,
          email: member.email,
          name: member.name,
          role: member.role.name,
          created_at: member.created_at
        }, status: :created
      else
        render json: { errors: member.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def login
      member = Member.find_by(email: params[:email])

      if member&.authenticate(params[:password])
        token = JsonWebToken.encode(member_id: member.id, role: member.role.name)
        render json: {
          token: token,
          user: {
            id: member.id,
            email: member.email,
            name: member.name,
            role: member.role.name
          }
        }, status: :ok
      else
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
    end

    def logout
      render json: { message: 'Logged out successfully' }, status: :ok
    end
  end
end