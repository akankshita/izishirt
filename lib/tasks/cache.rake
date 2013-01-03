namespace :cache do
  task(:clear => :environment) do

    action_to_clear = ENV['ACTION']
    expire_action :action=>action_to_clear
    expire_page :action=>action_to_clear


  end
end
 
