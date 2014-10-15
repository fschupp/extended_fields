class AnyuserCustomFieldFormat < Redmine::CustomFieldFormat

    def format_as_anyuser(value)
        User.find(value).name
    rescue
        nil
    end

    def edit_as
        'anyuser'
    end

end
