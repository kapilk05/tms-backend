Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    post 'auth/register', to: 'auth#register'
    post 'auth/login', to: 'auth#login'
    post 'auth/logout', to: 'auth#logout'

    resources :members, only: [:index, :show, :create, :update, :destroy]

    resources :tasks do
      member do
        post 'assign', to: 'tasks#assign'
        delete 'unassign/:member_id', to: 'tasks#unassign', as: 'unassign'
        get 'assignments', to: 'tasks#assignments'
      end
    end
  end

  root "rails/health#show"
end