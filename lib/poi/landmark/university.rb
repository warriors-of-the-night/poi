module POI
  module LandMark
    class University
      def initialize
        @base_url = "http://ziyuan.eol.cn/college.php"
      end

      def landmarks(prov)
        url   = "http://ziyuan.eol.cn/#{prov[:prov_href]}"
        @page = Nokogiri::HTML HTTParty.get(url).body 
        universities = {}
        1.upto(page_number) do |page_id|
          unless page_id==1
            url   = "http://ziyuan.eol.cn/#{prov[:prov_href]}&page=#{page_id}"
            @page = Nokogiri::HTML HTTParty.get(url).body
          end
          @page.search('//table/tr/td/table/tr/td/a').each { |univ|
            name = univ.text.to_s.gsub(/[（\(].*[\)）]/,'')
            universities[name] = {:source_domain=>'ziyuan.eol.cn',:cata=>'university'} if name!=' '
          }
        end
        universities
      end

      def page_number
        page_nav =  @page.search('//table/tr/td/font/font')[-1]
        page_nav.nil? ? 1 : page_nav.text[/(?<=共)(\d+)(?=页)/].to_i
      end

      def city_list
        @hp    = Nokogiri::HTML HTTParty.get(@base_url).body
        cities = @hp.search('//table/tbody/tr/td/p/b/font/../a')
        cities = cities.map do |city|
          { 
            :prov_cn   => city.text,
            :prov_href => city['href']
          }
        end
        cities
      end
    end
  end
end
