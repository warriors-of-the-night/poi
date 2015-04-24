require 'ruby-pinyin'
module POI
  module LandMark
    class BusStation
      def initialize 
        @city_url = "http://www.trip8080.com/chezhan/all.html"
      end

      def landmarks(city, max_recurse=1)
        return  {} if max_recurse>2
        lms   = {}
        url   = "http://www.trip8080.com/chengshi/getStationList.jspx?cityUrl=#{city[:cityUrl]}&page=1&rowNum=1000"
        ajax_json = HTTParty.get(url).body.to_s 
        if ajax_json.include?('</html>') 
          html    = HTTParty.get(city[:uri]).body.to_s
          cityUrl = html[/(?<=var cityUrl = \")(.*)(?=\")/]
          city[:cityUrl] = cityUrl
          landmarks(city, max_recurse+1) 
        else
          @json = JSON.parse(ajax_json) 
          @json['stationList'].each { |station|
          lms[station['STATION_NAME']] = {
            :cata          => 'bus_station',
            :source_domain => 'trip8080.com',
            :city_cn       => city[:name],
          }
        }
        end
       lms 
      end

      def city_list
        htm    = Nokogiri::HTML HTTParty.get(@city_url).body
        cities = htm.search('dl.all_list > dd > a').map do |city|
          name    = city['title']
          cityUrl = PinYin.sentence(name).gsub(/\s/,'') 
          {
            :name    => name,
            :cityUrl => cityUrl,
            :uri     => city['href']
          }
        end
      end

      def fix_missed(city, counter)
        html    = HTTParty.get(city[:uri]).body.to_s
        cityUrl = html[/(?<=var cityUrl = \")(.*)(?=\")/]
        city[:cityUrl] = cityUrl
        landmarks(city, counter)
      end

    end
  end
end
