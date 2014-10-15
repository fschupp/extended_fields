module ExtendedFields
	module IssuesControllerPatch
		def self.included(base)
			base.send(:include, InstanceMethods)

			base.class_eval do
				before_filter :authorize, :except => [:index, :extended_fields_autocomplete_for_user]
				unloadable

				def extended_fields_autocomplete_for_user
					if params[:q].length > 0
						@users = User.active.sorted.like(params[:q]).limit(50).all
						render :layout => false
					else
						render_403
					end
				end
			end
		end

		module InstanceMethods
		end
	end
end

IssuesController.send(:include, ExtendedFields::IssuesControllerPatch)
