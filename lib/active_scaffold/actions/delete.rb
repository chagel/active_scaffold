module ActiveScaffold::Actions
  module Delete
    def self.included(base)
      base.before_action :delete_authorized_filter, :only => [:destroy]
    end

    def destroy
      params.delete :destroy_action
      process_action_link_action(:destroy) do |record|
        do_destroy(record)
      end
    end

    protected

    def destroy_respond_to_html
      flash[:info] = as_(:deleted_model, :model => ERB::Util.h(@record.to_label)) if successful?
      return_to_main
    end

    def destroy_respond_to_js
      do_refresh_list if successful? && active_scaffold_config.delete.refresh_list && !render_parent?
      render(:action => 'destroy', layout: false)
    end

    def destroy_respond_to_xml
      render :xml => successful? ? '' : response_object, :only => active_scaffold_config.list.columns.names, :status => response_status
    end

    def destroy_respond_to_json
      render :json => successful? ? '' : response_object, :only => active_scaffold_config.list.columns.names, :status => response_status
    end

    def destroy_find_record
      @record = find_if_allowed(params[:id], :delete)
    end

    # A simple method to handle the actual destroying of a record
    # May be overridden to customize the behavior
    def do_destroy(record)
      record ||= destroy_find_record
      begin
        self.successful = record.destroy
      rescue StandardError => exception
        flash[:warning] = as_(:cant_destroy_record, :record => ERB::Util.h(record.to_label))
        self.successful = false
        logger.warn do
          "\n\n#{exception.class} (#{exception.message}):\n    " +
            Rails.backtrace_cleaner.clean(exception.backtrace).join("\n    ") +
            "\n\n"
        end
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def delete_authorized?(record = nil)
      (!nested? || !nested.readonly?) && (record || self).authorized_for?(crud_type: :delete, reason: true)
    end

    def delete_ignore?(record = nil)
      (nested? && nested.readonly?) || !authorized_for?(:crud_type => :delete)
    end

    private

    def delete_authorized_filter
      link = active_scaffold_config.delete.link || active_scaffold_config.delete.class.link
      raise ActiveScaffold::ActionNotAllowed unless Array(send(link.security_method))[0]
    end

    def destroy_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.delete.formats).uniq
    end
  end
end
