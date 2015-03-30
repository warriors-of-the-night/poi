module POI
  module LandMark
    class Train
      def initialize
        @base_url = 'http://www.gaotiewang.com/stationList.html'
      end

      def landmarks(city)
        pois = {}
        pois[city[:name]] = {
          :cata          => 'train',
          :city_cn       => city[:city_cn],
          :source_domain => 'gaotiewang.com'
        }
        pois
      end

      def city_list
        @page  = Nokogiri::HTML HTTParty.get(@base_url)
        cities = @page.search('//dd[@class="liW135"]/ul/li/a')
        cities = cities.map { |city|
          station = city.text
          {
            :name    => station,
            :city_cn => station.gsub(/(东|南|西|北)*火车站/,'')
          } 
        }
      end
      
      def html 
        @page.to_html
      end

    end
  end
end
