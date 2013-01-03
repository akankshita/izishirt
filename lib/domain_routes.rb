#
# This allows us to set up custom routes that depend on the domain or host of the request, ie:
# map.connect '', :controller => 'blah', :action => 'blah', :conditions => {:domain => 'blah'}
#

module ActionController
  module Routing
    class RouteSet
      def extract_request_environment(request)
        env = { :method => request.method }
        env[:domain] = request.domain if request.domain
        env[:domain] = request.domain(2) if env[:domain] == "co.uk" || env[:domain] == "com.au"
        env[:subdomain] = request.subdomains[0] if request.subdomains && request.subdomains[0]
        env[:host] = request.host if request.host
        env
      end
    end
    class Route
      alias_method :old_recognition_conditions, :recognition_conditions
      def recognition_conditions
        result = old_recognition_conditions
        result << "conditions[:domain] === env[:domain]" if conditions[:domain]
        result << "conditions[:subdomain] === env[:subdomain]" if conditions[:subdomain]
        result << "conditions[:host] === env[:host]" if conditions[:host]
        result
      end
    end
  end
end