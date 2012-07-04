set :application, "chef-solo"
set :chef_dir,    "/root/chef"
set :hostname,    `hostname -s`.chomp

require "json"
JSON.parse( open("#{chef_dir}/roles/base.json").read )["hosts"].keys.each do |host|
  role :host, host
end

namespace :chef do
  task :default do
    init_config
    sync
    merge_json
    run_chef
  end

  task :init_config do
    File::open("#{chef_dir}/config/solo.rb", "w") {|f|
      f.puts "file_cache_path '/tmp/chef-solo'"
      f.puts "cookbook_path   '#{chef_dir}/cookbooks'"
      f.puts "node_name       `hostname -s`.chomp"
    }
  end

  task :merge_json, :roles => :host do
    run "cd #{chef_dir} && export HOST=`hostname -s`; ./bin/merge_json roles/base.json roles/${HOST}.json > config/self.json"
  end

  desc "run chef-solo"
  task :run_chef, :roles => :host do
    run "chef-solo -c #{chef_dir}/config/solo.rb -j #{chef_dir}/config/self.json"
  end
 
  desc "rsync #{chef_dir}"
  task :sync do
    find_servers_for_task(current_task).each do |server|
      next if server.host == hostname 
      `rsync -avC --delete -e ssh --exclude config/self.json #{chef_dir}/ #{server.host}:#{chef_dir}/`
    end
  end

end

