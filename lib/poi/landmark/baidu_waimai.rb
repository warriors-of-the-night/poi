module POI
  module LandMark
    class BaiduWaimai
      def initialize
        @base_url = 'http://waimai.baidu.com/waimai?qt=find'
        @options  = {:headers => {"User-Agent" => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.73.11 (KHTML, like Gecko) Version/7.0.1 Safari/537.73.11'}
        }
      end
      
      def landmarks(city)
        return [] if !city[:isHaveAoi]
        url     = "http://waimai.baidu.com/waimai?qt=getcitylist&city_id=#{city[:city_id]}"
      # city_en = PinYin.sentence(city['name']).gsub(/\s/,"")
        @aois   = {}
        JSON.parse(HTTParty.get(url,@options).body)['result']['aois'].each do |center, aoi|
          aoi.each { |center|
            city.delete(:isHaveAoi)          
            @aois[center['name']]= {
                      :source_domain => 'waimai.baidu.com',
                      :cata          => 'center',
           #  				:city_en =>  city_en,
            }.merge(city)
         }
        end
        @aois
      end

      def city_list
        @page = Nokogiri::HTML HTTParty.get(@base_url, @options)
        script_json = @page.at('//script[contains(text(),"city_list")]').text
        cities      = JSON.parse('{"city_list":' + script_json[/(?<="city_list":)(.*)(?=,"landing_cfg")/]+"}")
        cities      = cities['city_list'].map { |city| {:city_id=>city['code'],:city_cn=>city['name'],:isHaveAoi=>city['isHaveAoi']} }
      end
      
      def html
        @page.to_html
      end
    end
  end
end


        


