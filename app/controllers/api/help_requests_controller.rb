module Api
  class HelpRequestsController < ApplicationController
    before_action :set_help_request, only: [:answer]
    before_action :authorize_admin, only: [:answer]

    # GET /api/help_requests/admins
    def admins
      admins = Member.joins(:role).where(roles: { name: Role::ADMIN })
      render json: {
        admins: admins.map { |m| { id: m.id, name: m.name, email: m.email } }
      }
    end

    # POST /api/help_requests
    def create
      admin = Member.joins(:role).find_by(id: params[:admin_id], roles: { name: Role::ADMIN })

      if admin.nil?
        render json: { error: 'Admin not found' }, status: :not_found
        return
      end

      help_request = HelpRequest.new(
        requester: current_user,
        admin: admin,
        question: params[:question]
      )

      if help_request.save
        render json: help_request_json(help_request), status: :created
      else
        render json: { errors: help_request.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # GET /api/help_requests
    def index
      if current_user.role.name == Role::ADMIN
        help_requests = HelpRequest.includes(:requester, :admin, :help_answer)
                                   .where(admin_id: current_user.id)
                                   .order(created_at: :desc)
      else
        help_requests = HelpRequest.includes(:requester, :admin, :help_answer)
                                   .where(requester_id: current_user.id)
                                   .order(created_at: :desc)
      end

      render json: {
        help_requests: help_requests.map { |r| help_request_json(r) }
      }
    end

    # POST /api/help_requests/:id/answer
    def answer
      unless @help_request.admin_id == current_user.id
        render json: { error: 'Forbidden' }, status: :forbidden
        return
      end

      answer = @help_request.help_answer || @help_request.build_help_answer(admin: current_user)
      answer.answer = params[:answer]

      if answer.save
        @help_request.update(status: HelpRequest::STATUS_ANSWERED)
        render json: help_request_json(@help_request), status: :ok
      else
        render json: { errors: answer.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_help_request
      @help_request = HelpRequest.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Help request not found' }, status: :not_found
    end

    def authorize_admin
      unless current_user.role.name == Role::ADMIN
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end

    def help_request_json(help_request)
      {
        id: help_request.id,
        question: help_request.question,
        status: help_request.status,
        requester: {
          id: help_request.requester.id,
          name: help_request.requester.name,
          email: help_request.requester.email
        },
        admin: {
          id: help_request.admin.id,
          name: help_request.admin.name,
          email: help_request.admin.email
        },
        answer: help_request.help_answer&.answer,
        answered_at: help_request.help_answer&.created_at,
        created_at: help_request.created_at
      }
    end
  end
end
