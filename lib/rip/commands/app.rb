require 'sinatra'

class RipServer < Sinatra::Default
  helpers do
    def generate_rdoc(package)
      # return %x{cd #{package.cache_path} && rdoc}
      
      puts "Generating RDocs on the following files:\n\t%s" % Dir.glob(File.join(package.cache_path, '**', '*.{rb,rdoc}')).join("\n\t")
      
      require 'rdoc/rdoc'
      r = RDoc::RDoc.new
      r.document([
        "--op", File.join(package.cache_path, 'doc'),
        "--inline-source",
        "--title", "%s (%s) RDoc Documentation" % [package.name, package.version],
        "--quiet",
        # "--exclude", File.join(package.cache_path, '(spec|test)', '.*.rb'),
        *Dir.glob(File.join(package.cache_path, '**', '*.{rb,rdoc}'))
        # *Dir.glob(File.join(package.cache_path, 'lib', '**', '*.{rb,rdoc}'))
        # *package.files
      ])
    end
  end
  
  get '/' do
    erb :index
  end
  
  get '/rdoc/:name' do
    @package = $MANAGER.package(params[:name])
    redirect "/rdoc/%s/index.html" % @package.name
  end
  
  get '/rdoc/:name/generate' do
    @package = $MANAGER.package(params[:name])
    if params[:start]
      generate_rdoc(@package)
      redirect "/rdoc/%s/index.html" % @package.name, "RDoc generated for #{@package.name}"
    else
      redirect "/rdoc/%s/generate?start=true" % @package.name, "Generating RDoc for #{@package.name}"
    end
  end
  
  get '/rdoc/:name/*' do
    @package = $MANAGER.package(params[:name])
    if File.exist?(File.join(@package.cache_path, 'doc'))
      file_env = env.dup
      file_env['PATH_INFO'] = File.join(*params[:splat])
      Rack::File.new(File.join(@package.cache_path, 'doc')).call(file_env)
    else
      redirect "/rdoc/%s/generate" % @package.name, "Generating RDoc for %s" % @package.name
    end
  end
end