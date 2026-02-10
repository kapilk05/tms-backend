module Api
  class TasksController < ApplicationController
    before_action :set_task, only: [:show, :update, :destroy, :assign, :unassign, :assignments, :complete]
    before_action :authorize_owner_or_admin, only: [:update, :destroy]
    before_action :authorize_assignment, only: [:assign, :unassign]
    before_action :authorize_assignee, only: [:complete]

    def index
      page = params[:page] || 1
      per_page = [params[:per_page].to_i, 100].min || 10
      
      tasks = Task.includes(:created_by, :assigned_members)
               .left_joins(:task_assignments)
               .where("tasks.created_by_id = ? OR task_assignments.member_id = ?", 
                      current_user.id, current_user.id)
               .distinct
      
      tasks = tasks.where(status: params[:status]) if params[:status].present?
      tasks = tasks.where(priority: params[:priority]) if params[:priority].present?
      tasks = tasks.order(params[:sort] || :created_at)
      
      paginated_tasks = tasks.page(page).per(per_page)
      total_count = tasks.count

      render json: {
        tasks: paginated_tasks.map { |t| task_summary_json(t) },
        pagination: {
          current_page: page.to_i,
          per_page: per_page,
          total_pages: (total_count.to_f / per_page).ceil,
          total_count: total_count
        }
      }
    end

    def show
      render json: task_detail_json(@task)
    end

    def create
      task = Task.new(task_params)
      task.created_by = current_user

      if task.save
        render json: task_detail_json(task), status: :created
      else
        render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @task.update(task_params)
        render json: task_detail_json(@task)
      else
        render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @task.destroy
      render json: { message: 'Task deleted successfully' }, status: :ok
    end

    def assign
      member_ids = params[:member_ids] || []
      
      member_ids.each do |member_id|
        member = Member.find_by(id: member_id)
        next unless member
        
        TaskAssignment.find_or_create_by(task: @task, member: member)
      end

      render json: {
        id: @task.id,
        title: @task.title,
        assigned_users: @task.assigned_members.map { |m| { id: m.id, name: m.name } }
      }
    end

    def unassign
      member = Member.find(params[:member_id])
      assignment = TaskAssignment.find_by(task: @task, member: member)
      
      if assignment
        assignment.destroy
        render json: { message: 'Member unassigned successfully' }, status: :ok
      else
        render json: { error: 'Assignment not found' }, status: :not_found
      end
    end

    def assignments
      render json: {
        task_id: @task.id,
        assigned_users: @task.assigned_members.map { |m| 
          { 
            id: m.id, 
            name: m.name, 
            email: m.email,
            assigned_at: @task.task_assignments.find_by(member: m).assigned_at,
            completed_at: @task.task_assignments.find_by(member: m).completed_at,
            completion_comment: @task.task_assignments.find_by(member: m).completion_comment
          } 
        }
      }
    end

    def complete
      assignment = TaskAssignment.find_by(task: @task, member: current_user)

      if assignment.nil?
        render json: { error: 'Not assigned to this task' }, status: :forbidden
        return
      end

      if assignment.update(completed_at: Time.current, completion_comment: params[:comment])
        if @task.task_assignments.where(completed_at: nil).count.zero?
          @task.update(status: 'completed')
        end

        render json: {
          task: task_detail_json(@task),
          assignment: {
            member_id: current_user.id,
            completed_at: assignment.completed_at,
            completion_comment: assignment.completion_comment
          }
        }, status: :ok
      else
        render json: { errors: assignment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_task
      task_id = params[:id] || params[:task_id]
      if task_id.nil?
        render json: { error: 'Task id is required' }, status: :bad_request
        return
      end

      @task = Task.find(task_id)
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Task not found' }, status: :not_found
    end

    def task_params
      params.permit(:title, :description, :status, :priority, :due_date)
    end

    def task_summary_json(task)
      {
        id: task.id,
        title: task.title,
        status: task.status,
        priority: task.priority,
        due_date: task.due_date,
        assigned_users: task.assigned_members.map { |m| { id: m.id, name: m.name } }
      }
    end

    def task_detail_json(task)
      {
        id: task.id,
        title: task.title,
        description: task.description,
        status: task.status,
        priority: task.priority,
        due_date: task.due_date,
        created_by: {
          id: task.created_by.id,
          name: task.created_by.name
        },
        assigned_users: task.assigned_members.map { |m| { id: m.id, name: m.name } },
        created_at: task.created_at,
        updated_at: task.updated_at
      }
    end

    def authorize_owner_or_admin
      unless @task.created_by_id == current_user.id || current_user.role.name == 'admin'
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end

    def authorize_assignment
      unless ['admin', 'manager'].include?(current_user.role.name) || @task.created_by_id == current_user.id
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end

    def authorize_assignee
      unless @task.assigned_members.exists?(id: current_user.id)
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end