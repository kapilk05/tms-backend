module Api
  class TasksController < ApplicationController
    before_action :set_task, only: [:show, :update, :destroy, :assign, :unassign, :assignments]
    before_action :authorize_owner_or_admin, only: [:update, :destroy]
    before_action :authorize_assignment, only: [:assign, :unassign]

    # GET /api/tasks
    def index
      page = params[:page] || 1
      per_page = [params[:per_page].to_i, 100].min || 10
      
      # Get tasks where user is creator OR assigned to
      tasks = Task.includes(:created_by, :assigned_members)
               .left_joins(:task_assignments)
               .where("tasks.created_by_id = ? OR task_assignments.member_id = ?", 
                      current_user.id, current_user.id)
               .distinct
      
      # Apply filters
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

    # GET /api/tasks/:id
    def show
      render json: task_detail_json(@task)
    end

    # POST /api/tasks
    def create
      task = Task.new(task_params)
      task.created_by = current_user

      if task.save
        render json: task_detail_json(task), status: :created
      else
        render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PUT /api/tasks/:id
    def update
      if @task.update(task_params)
        render json: task_detail_json(@task)
      else
        render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/tasks/:id
    def destroy
      @task.destroy
      render json: { message: 'Task deleted successfully' }, status: :ok
    end

    # POST /api/tasks/:id/assign
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

    # DELETE /api/tasks/:id/unassign/:member_id
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

    # GET /api/tasks/:id/assignments
    def assignments
      render json: {
        task_id: @task.id,
        assigned_users: @task.assigned_members.map { |m| 
          { 
            id: m.id, 
            name: m.name, 
            email: m.email,
            assigned_at: @task.task_assignments.find_by(member: m).assigned_at
          } 
        }
      }
    end

    private

    def set_task
      @task = Task.find(params[:id])
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
  end
end