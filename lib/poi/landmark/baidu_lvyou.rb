module POI
  module LandMark
    class BaiduLvyou

      def initialize
        @destination = "http://lvyou.baidu.com/destination/"
      end

      def landmarks(city) 
        city_en = city[:city_en]
        scenes  = {}
        @html = HTTParty.get("http://lvyou.baidu.com/destination/ajax/jingdian?format=ajax&surl=#{city_en}&cid=0&pn=1").body
        1.upto(pg_number).each do |pn|
          @html = HTTParty.get("http://lvyou.baidu.com/destination/ajax/jingdian?format=ajax&surl=#{city_en}&cid=0&pn=#{pn}").body if pn >1
          json  = JSON.parse(@html)
          json['data']['scene_list'].each do |scene|
            name = scene['ambiguity_sname']
            scenes[name] = {
              :city_cn       => city[:city_cn],
              :cata          => 'scene',
              :source_domain => 'lvyou.baidu.com'
            }
          end
         end 
        scenes
      end
      
      def city_list 
        @dt_pg = Nokogiri::HTML HTTParty.get(@destination).body
        cities = @dt_pg.search('//ul[@class="china-visit-list nslog-area"]')[0].xpath('./li/p/a').map do |city|
          {
            :city_cn => city.text,
            :city_en => city['href'].gsub(/\//,''),
          }
        end
      end

      def pg_number
        ajax_json   = JSON.parse(@html)
        scene_total = ajax_json['data']['scene_total']
        (scene_total+15)/16
      end
    end
  end
end








