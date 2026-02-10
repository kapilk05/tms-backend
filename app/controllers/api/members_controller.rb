module Api
  class MembersController < ApplicationController
    before_action :set_member, only: [:show, :update, :destroy]
    before_action :authorize_admin, only: [:create, :destroy]
    before_action :authorize_admin_or_manager, only: [:index]
    before_action :authorize_admin_or_self, only: [:update]

    def index
      page = params[:page] || 1
      per_page = [params[:per_page].to_i, 100].min || 20
      
      members = Member.includes(:role)
      members = members.joins(:role).where(roles: { name: params[:role] }) if params[:role].present?
      
      paginated_members = members.page(page).per(per_page)
      total_count = members.count

      render json: {
        members: paginated_members.map { |m| member_json(m) },
        pagination: {
          current_page: page.to_i,
          per_page: per_page,
          total_pages: (total_count.to_f / per_page).ceil,
          total_count: total_count
        }
      }
    end

    def show
      authorize_admin_or_manager_or_self(@member)
      render json: member_json(@member)
    end

    def create
      role = Role.find_or_create_by(name: params[:role_name] || 'user')
      
      member = Member.new(
        email: params[:email],
        password: params[:password],
        name: params[:name],
        role: role
      )

      if member.save
        render json: member_json(member), status: :ok
      else
        render json: { errors: member.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @member.update(member_params)
        render json: member_json(@member)
      else
        render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @member.destroy
      render json: { message: 'Member deleted successfully' }, status: :ok
    end

    private

    def set_member
      @member = Member.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Member not found' }, status: :not_found
    end

    def member_params
      params.permit(:email, :name, :password)
    end

    def member_json(member)
      {
        id: member.id,
        email: member.email,
        name: member.name,
        role: member.role.name,
        created_at: member.created_at
      }
    end

    def authorize_admin
      render json: { error: 'Forbidden' }, status: :forbidden unless current_user.role.name == 'admin'
    end

    def authorize_admin_or_manager
      unless ['admin', 'manager'].include?(current_user.role.name)
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end

    def authorize_admin_or_self
      unless current_user.role.name == 'admin' || current_user.id == @member.id
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end

    def authorize_admin_or_manager_or_self(member)
      unless ['admin', 'manager'].include?(current_user.role.name) || current_user.id == member.id
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end