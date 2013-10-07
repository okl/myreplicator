Myreplicator::Engine.routes.draw do
  resources :exports
  root :to => "home#index"
  get '/export_errors', :to => "home#export_errors", :as => 'export_errors'
  get '/transport_errors', :to => "home#transport_errors", :as => 'transport_errors'
  get '/load_errors', :to => "home#load_errors", :as => 'load_errors'
  get '/kill/:id', :to => 'home#kill', :as => 'kill'
  get '/search', :to => "exports#search"
  
  resources :home do
    get :pause, :on => :collection
    get :resume, :on => :collection
  end
  
  resources :exports do
    get :search, :on => :collection
    member do
      get 'reload'
    end
  end
end
