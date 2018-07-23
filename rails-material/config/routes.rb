Rails.application.routes.draw do
  get 'sensing/codes'
  get 'sensing/vid'

  resources :participants do
  	member do 
  		resources :captures,  as: :mycaptures
  	end
  end
  resources :captures 
  get 'study/log'

  namespace :notebook do
    get 'guide'
    get 'debugging'
    post 'save_file'
    get 'capture'
    get 'joule'
    get 'print'
  end
	namespace :material do 
		get 'annotator'
  		get 'vision'
  		get 'conversion'
  		get 'websocket_test'
  		get 'designer'
  		get 'camera'
  		get 'setup'
  		get 'video_feed'
	end
 
	
	resources :captures 
	devise_for :users, controllers: { confirmations: 'confirmations',  omniauth_callbacks: "omniauth_callbacks"}
	resources :user do 
		member do 
			get 'captures' => "user#captures"
		end
	end

	# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	root 'application#home'
end
