require "json"

set :application, "chef-solo"
set :chef_dir,    "/root/chef"
set :hostname,    `hostname -s`.chomp
set :json_dir,    "#{chef_dir}/json"
set :config_dir,  "#{chef_dir}/config"
set :bin_dir,     "#{chef_dir}/bin"
set :base,        JSON.parse( File::open("#{json_dir}/base.json").read )

if exists? :hosts
  hosts.split(",").each do |host|
    role :host, host
  end
else
  base["hosts"].keys.sort.each do |host|
    role :host, host
  end
end

namespace :chef do

  task :default do
    init_config
    sync
    merge_json
    run_chef
  end

  task :init_config do
    File::open("#{config_dir}/solo.rb", "w") {|f|
      f.puts "file_cache_path '/tmp/chef-solo'"
      f.puts "cookbook_path   '#{chef_dir}/cookbooks'"
      f.puts "node_name       `hostname -s`.chomp"
    }
  end

  task :merge_json, :roles => :host do
    run "export HOST=`hostname -s`; #{bin_dir}/merge_json #{json_dir}/base.json #{json_dir}/${HOST}.json > #{config_dir}/self.json"
  end

  desc "run chef-solo"
  task :run_chef, :roles => :host do
    run "chef-solo -c #{config_dir}/solo.rb -j #{config_dir}/self.json"
  end

  desc "rsync #{chef_dir}"
  task :sync do
    find_servers_for_task(current_task).each do |server|
      next if server.host == hostname
      `rsync -avC --delete -e ssh --exclude config/self.json #{chef_dir}/ #{server.host}:#{chef_dir}/`
    end
  end

end

