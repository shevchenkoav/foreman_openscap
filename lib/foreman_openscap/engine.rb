require 'deface'
require 'scaptimony/engine'

module ForemanOpenscap
  class Engine < ::Rails::Engine

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/overrides"]

    # Add any db migrations
    initializer "foreman_openscap.load_app_instance_data" do |app|
      app.config.paths['db/migrate'] += Scaptimony::Engine.paths['db/migrate'].existent
      app.config.paths['db/migrate'] += ForemanOpenscap::Engine.paths['db/migrate'].existent
    end

    initializer 'foreman_openscap.register_plugin', :after=> :finisher_hook do |app|
      Foreman::Plugin.register :foreman_openscap do
        requires_foreman '>= 1.5'

        # Add permissions
        security_block :foreman_openscap do
          permission :view_arf_reports, {:arf_reports => [:index, :show] }
        end

        # Add a new role called 'Discovery' if it doesn't exist
        role "OpenSCAP reports view", [:view_arf_reports]

        #add menu entry
        menu :top_menu, :template,
             :url_hash => {:controller => :'arf_reports', :action => :index },
             :caption  => 'Compliance',
             :parent   => :hosts_menu,
             :after    => :hosts
      end
    end

    #Include concerns in this config.to_prepare block
    config.to_prepare do
      begin
        Host::Managed.send(:include, ForemanOpenscap::HostExtensions)
        HostsHelper.send(:include, ForemanOpenscap::HostsHelperExtensions)
        ::Scaptimony::ArfReport.send(:include, ForemanOpenscap::ArfReportExtensions)
      rescue => e
        puts "ForemanOpenscap: skipping engine hook (#{e.to_s})"
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        Scaptimony::Engine.load_seed
        ForemanOpenscap::Engine.load_seed
      end
    end

  end
end