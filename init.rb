require 'redmine'

require_dependency 'extended_fields_hook'
require_dependency 'patches/issues_controller.rb'
require_dependency 'patches/projects_controller.rb'

Rails.logger.info 'Starting Extended Fields plugin for Redmine'

unless defined?(Redmine::CustomFieldFormat)
    require_dependency 'extended_field_format'
end

if defined?(Redmine::CustomFieldFormat)
    Redmine::CustomFieldFormat.map do |fields|
        if Redmine::VERSION::MAJOR < 2 || defined?(ChiliProject)
            base_order = 2
        else
            base_order = 1
        end

        fields.register AnyuserCustomFieldFormat.new('anyuser', :label => :label_anyuser,   :order => base_order + 1)
        fields.register    WikiCustomFieldFormat.new('wiki',    :label => :label_wiki_text, :order => base_order + 2)
        fields.register    LinkCustomFieldFormat.new('link',    :label => :label_link,      :order => base_order + 3)
        fields.register ProjectCustomFieldFormat.new('project', :label => :label_project,   :order => base_order + 4)
    end
end

issue_query = (IssueQuery rescue Query)

issue_query.add_available_column(ExtendedQueryColumn.new(:notes,
                                                         :value => lambda { |issue| issue.journals.select{ |journal| journal.notes.present? }.size }))

issue_query.add_available_column(ExtendedQueryColumn.new(:changes,
                                                         :caption => :label_change_plural,
                                                         :value => lambda { |issue| issue.journals.select{ |journal| journal.details.any? }.size }))

issue_query.add_available_column(ExtendedQueryColumn.new(:watchers,
                                                         :caption => :label_issue_watchers,
                                                         :value => lambda { |issue| issue.watchers.size }))

Rails.configuration.to_prepare do

    unless String.method_defined?(:html_safe)
        String.send(:include, ExtendedStringHTMLSafePatch)
    end

    unless ActionView::Base.included_modules.include?(ExtendedFieldsHelper)
        ActionView::Base.send(:include, ExtendedFieldsHelper)
    end

    unless defined? ActiveSupport::SafeBuffer
        unless ActionView::Base.included_modules.include?(ExtendedHTMLEscapePatch)
            ActionView::Base.send(:include, ExtendedHTMLEscapePatch)
        end
    end

    unless AdminController.included_modules.include?(ExtendedAdminControllerPatch)
        AdminController.send(:include, ExtendedAdminControllerPatch)
    end
    unless UsersController.included_modules.include?(ExtendedUsersControllerPatch)
        UsersController.send(:include, ExtendedUsersControllerPatch)
    end
    unless IssuesController.included_modules.include?(ExtendedIssuesControllerPatch)
        IssuesController.send(:include, ExtendedIssuesControllerPatch)
    end
    if ActiveRecord::Base.connection.adapter_name =~ %r{mysql}i
        unless CalendarsController.included_modules.include?(ExtendedCalendarsControllerPatch)
#            CalendarsController.send(:include, ExtendedCalendarsControllerPatch)
        end
    end
    if Redmine::VERSION::MAJOR == 2 && Redmine::VERSION::MINOR < 5
        unless ApplicationHelper.included_modules.include?(ExtendedApplicationHelperPatch)
            ApplicationHelper.send(:include, ExtendedApplicationHelperPatch)
        end
    end
    unless QueriesHelper.included_modules.include?(ExtendedQueriesHelperPatch)
        QueriesHelper.send(:include, ExtendedQueriesHelperPatch)
    end
    unless CustomFieldsHelper.included_modules.include?(ExtendedFieldsHelperPatch)
        CustomFieldsHelper.send(:include, ExtendedFieldsHelperPatch)
    end
    if defined?(Redmine::CustomFieldFormat)
        unless CustomField.included_modules.include?(ExtendedCustomFieldPatch)
            CustomField.send(:include, ExtendedCustomFieldPatch)
        end
    end
    begin
        unless CustomFieldValue.included_modules.include?(ExtendedCustomFieldValuePatch)
            CustomFieldValue.send(:include, ExtendedCustomFieldValuePatch)
        end
    rescue NameError
    end
    unless CustomValue.included_modules.include?(ExtendedCustomValuePatch)
        CustomValue.send(:include, ExtendedCustomValuePatch)
    end
    if defined?(Redmine::CustomFieldFormat)
        unless Query.included_modules.include?(ExtendedCustomQueryPatch)
            Query.send(:include, ExtendedCustomQueryPatch)
        end
    end
    unless Project.included_modules.include?(ExtendedProjectPatch)
        Project.send(:include, ExtendedProjectPatch)
    end
    unless User.included_modules.include?(ExtendedUserPatch)
        User.send(:include, ExtendedUserPatch)
    end

    unless AdminController.included_modules.include?(CustomFieldsHelper)
        AdminController.send(:helper, :custom_fields)
        AdminController.send(:include, CustomFieldsHelper)
    end
    unless WikiController.included_modules.include?(CustomFieldsHelper)
        WikiController.send(:helper, :custom_fields)
        WikiController.send(:include, CustomFieldsHelper)
    end

    if defined? ActionView::OptimizedFileSystemResolver
        unless ActionView::OptimizedFileSystemResolver.method_defined?(:[])
            ActionView::OptimizedFileSystemResolver.send(:include, ExtendedFileSystemResolverPatch)
        end
    end

    if CustomField.method_defined?(:format_in?)
        unless CustomField.included_modules.include?(ExtendedFormatInPatch)
            CustomField.send(:include, ExtendedFormatInPatch)
        end
    end

    if defined? XlsExportController
        unless XlsExportController.included_modules.include?(ExtendedFieldsHelper)
            XlsExportController.send(:include, ExtendedFieldsHelper)
        end
    end
end

Redmine::Plugin.register :extended_fields do
    name 'Extended fields'
    author 'Felix Schupp (based on Andriy Lesyuk)'
    author_url 'http://www.andriylesyuk.com'
    description 'Adds new custom field types, improves listings etc.'
    url 'https://github.com/fschupp/extended_fields'
    version '0.3.0'

    project_module :assign_to_any_user do
        permission :project_extended_fields_autocomplete_for_user, {:projects => [:extended_fields_autocomplete_for_user]}, :public => true, :read => true
        permission :issue_extended_fields_autocomplete_for_user,   {:issues   => [:extended_fields_autocomplete_for_user]}, :public => true, :read => true
    end
end
