
template "/etc/resolv.conf" do
  source "resolv.conf.erb"
  owner "root"
  mode  0644
end

