module POI
  module LandMark
    class ElongFlight
      def initialize
        @base_url = 'http://flight.elong.com/airports.html'
      end

      def landmarks(city)
        pois = {}
        pois[city[:name]] = {
          :city_cn        => city[:city_cn],
          :cata           => 'flight',
          :source_domain  => 'flight.elong.com',
        }
        pois
      end

      def city_list
        @page  = Nokogiri::HTML HTTParty.get(@base_url)
        cities = @page.search('//ul[@class="seo_timetable seo_all"]/li/ul/li')
        cities = cities.map{ |city|
          {
            :city_cn => city.at('./b').text,
            :name    => city.at('./a').text,
          }
        }
      end
      
      def html
        @page.to_html
      end
    end
  end
end
