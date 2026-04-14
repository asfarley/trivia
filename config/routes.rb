Rails.application.routes.draw do
  devise_for :users

  root "pages#landing"

  resources :question_sets do
    collection do
      get  :import
      post :import
    end
    member do
      get  :study
      post :check_answer
      patch :pin
    end
    resources :questions, only: [ :index, :create, :update, :destroy ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
