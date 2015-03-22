module POI
  module LandMark
    class BaiduWaimai
      def initialize
        @base_url = 'http://map.baidu.com/waimai?qt=find'
      end
      
      def landmarks(city)
        return [] if !city['isHaveAoi']
        url     = "http://map.baidu.com/waimai?qt=getcitylist&city_id=#{city['code']}"
        city_en = PinYin.sentence(city['name']).gsub(/\s/,"")
        @aois   = {}
        JSON.parse(HTTParty.get(url).body)['result']['aois'].each do |center, aoi|
          aoi.each { |landmark|           
            @aois[landmark['name']]= {
             					:city_id =>  city['code'],
             					:city_cn =>  city['name'],
             					:city_en =>  city_en,
            }
          }
        end
        @aois
      end

      def city_list
        @page = Nokogiri::HTML HTTParty.get(@base_url)
        script_text = @page.at('//script[contains(text(),"city_list")]').text
        city_set    = JSON.parse('{"city_list":' + script_text[/(?<="city_list":)(.*)(?=,"landing_cfg")/]+"}")
        city_set['city_list']
      end
      
      def html
        @page.to_html
      end
    end
  end
end


        


