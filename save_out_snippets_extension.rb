require_dependency 'application'

module ShareSnippets
  module SnippetExt
    def after_save
      share_config = SaveOutSnippetsExtension::current_config
      
      for share in share_config.select {|s| s[:name] == name}
        
        # create a dummy page to our specifications so that we can render the radius tags
        new_page = Page.new(:title => share[:title], :slug => share[:slug], :breadcrumb => share[:breadcrumb])
        new_page.created_at = new_page.updated_at = Time.now
        
        # write to file, inserting the extra markup specified
        File.open(share[:file], 'w') {|f| f.write([share[:before], new_page.render_snippet(self), share[:after]]) }
      end
      
    end
  end
end

class SaveOutSnippetsExtension < Radiant::Extension
  
  version "1.0"
  description "This plugin shares your Radiant Snippets with other programs"
  url "http://www.marginleft.com"
  
  define_routes do |map|
    map.connect 'admin/share_snippets/:action', :controller => 'admin/share_snippets'
  end
  
  def activate
    base_config = []
    File.open(config_path, 'w') {|f| f.write(base_config.to_yaml) } if !File.exist?(config_path)
    admin.tabs.add "Snippet Sharing", "/admin/share_snippets", :after => "Blog Feeds", :visibility => [:all]
    Snippet.send :include, ShareSnippets::SnippetExt
  end
  
  def deactivate
    admin.tabs.remove "Snippet Sharing"
  end
  
  def config_path
    defined?(SHARE_SNIPPETS_CONFIG_FILE_PATH) ? SHARE_SNIPPETS_CONFIG_FILE_PATH : "#{RAILS_ROOT}/config/share_snippets.yml"
  end
  
  def current_config
    YAML::load(File.open(config_path))
  end
  
end
