module POI
  module LandMark
    class Embassy
      def initialize
        @url = 'http://www.safea.gov.cn/embassies.php'
      end

      def landmarks(city)
        page = Nokogiri::HTML(HTTParty.get(@url).body ,nil,"GB2312")
        pois = page.search('//table/tr/td[@width="50%"]/text()[1]')
        embassies = {}
        pois.each { |poi|
          name = poi.text.gsub(/\s/,'')
          embassies[name] = {
            :cata          =>  'embassy',
            :source_domain =>  'safea.gov.cn',
          }.merge(city)
        }
        embassies   
      end

      def city_list
        [{ :city_cn=>'北京'}]
      end

    end
  end
end
