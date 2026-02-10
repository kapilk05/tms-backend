Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    post 'auth/register', to: 'auth#register'
    post 'auth/login', to: 'auth#login'
    post 'auth/logout', to: 'auth#logout'

    resources :members, only: [:index, :show, :create, :update, :destroy] do
      collection do
        get 'me', to: 'members#me'
      end
    end

    resources :tasks do
      member do
        post 'assign', to: 'tasks#assign'
        delete 'unassign/:member_id', to: 'tasks#unassign', as: 'unassign'
        get 'assignments', to: 'tasks#assignments'
        post 'complete', to: 'tasks#complete'
      end
    end

    resources :help_requests, only: [:create, :index] do
      collection do
        get 'admins', to: 'help_requests#admins'
      end

      member do
        post 'answer', to: 'help_requests#answer'
      end
    end
  end

  root "rails/health#show"
end