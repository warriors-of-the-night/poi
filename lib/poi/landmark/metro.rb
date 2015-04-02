module POI
  module LandMark
    class Metro
      def initialize
        @base_url   = 'http://map.baidu.com/subways/sbw.min.js?'
      end

      def landmarks(city)
        metro_json  = JSON.parse(HTTParty.get("http://map.baidu.com/?qt=bsi&c=#{city[:city_id]}").body)
        lines       = metro_json['content']
        return {} if !lines
        metros = {}
        lines.each do |line|
          line['stops'].each {  |stop|
            metros[stop['name']] = {
              :city_cn       => city[:city_cn],
              :cata          => 'metro',
              :source_domain => 'map.baidu.com',
            }
          }
        end
        metros
      end
      
      def city_list
        @js_content = HTTParty.get(@base_url).body
        area_uid    = @js_content[/(?<=areaUID=).*(?="\.split\(","\))/]
        cities      = area_uid.split(',').map { |city| 
          name_code = city.split('|')
          {
            :city_cn => name_code[0].to_s.force_encoding("UTF-8"),
            :city_id => name_code[1],
          }
        }
        cities
      end
    end
  end
end
