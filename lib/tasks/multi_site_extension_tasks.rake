namespace :radiant do
  namespace :extensions do
    namespace :multi_site do
      
      desc "Runs the migration of the Multi Site extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          MultiSiteExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          MultiSiteExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Multi Site to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[MultiSiteExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(MultiSiteExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end
      
      desc "Transforms an old virtual domain setup into multi_site setup"
      task :transform => :environment do
        @vdp = Page.find_all_by_class_name("VirtualDomainPage")
        @vdp.each{|page| page.update_attributes(:class_name => "Page", :title => %Q(#{page.title} Virtual Domain #{page.id}) )}
        @pages = Page.find_all_by_parent_id_and_class_name(1,"Page")
        @pages.each do |page|
          Site.create(:domain => page.slug.gsub("-","."), :base_domain => page.slug.gsub("-","."), :name => (x = page.title.gsub(/[^A-Z]/,"").gsub(/NR([A-Z]+)/,'\1')).blank? ? page.title : x, :homepage_id => page.id)
          page.update_attributes(:parent_id => nil)
        end
      end
    end
  end
end
