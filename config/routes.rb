RedmineApp::Application.routes.draw do
	resources :projects do
		member do
			get 'extended_fields_autocomplete_for_user',	:to => 'projects#extended_fields_autocomplete_for_user'
		end
	end
	get 'issues/:id/extended_fields_autocomplete_for_user',		:to => 'issues#extended_fields_autocomplete_for_user'
end

