module Catalog
  # robots.txt served by the app so the sitemap URL always matches the
  # deployment host.
  class RobotsController < ApplicationController
    def show
      render plain: <<~ROBOTS
        User-agent: *
        Allow: /

        Sitemap: #{root_url}sitemap.xml
      ROBOTS
    end
  end
end
