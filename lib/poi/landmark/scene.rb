module POI
  module LandMark
    class Scene
      def initialize
        @base_url = 'http://www.mafengwo.cn/mdd/'
      end
      
      def landmarks(city)
        city_id   =  city[:city_id]
        base_info =  { :cata=>'scene', :source_domain=>'mafengwo.cn'}.merge(city)
        @gl_html  =  Nokogiri::HTML HTTParty.get("http://www.mafengwo.cn/jd/#{city_id}/gonglve.html").body
        pois      =  @gl_html.at_css('div.list')
        ats       =  {}
        if pois
          pois.search('./ul/li/a/strong').each do |poi| ats[poi.text] = base_info end
        else
          pg_nb   = page_number
          1.upto(pg_nb) do |i|
            url    =  "http://www.mafengwo.cn/jd/#{city_id}/0-0-0-0-0-#{i}.html"
            @page  =  Nokogiri::HTML HTTParty.get(url).body
            poi_ls =  @page.search('//ul[@class="poi-list"]/li/div[@class="title"]/h3/a')
            poi_ls.each { |poi| ats[poi.text] = base_info }
          end
        end
        ats
      end
      
      def page_number
        pn_elem = @gl_html.at('//span[@class="count"]/span')
        pn_elem.nil? ? 1 : pn_elem.text.to_i
      end

      def city_list
        mdd      = Nokogiri::HTML HTTParty.get(@base_url).body
        row_list = mdd.search('//div[@class="row-list"]/h2[contains(text(),"国内目的地")]/../div/dl/dd/ul/li/a')
        cities   = row_list.map { |row|
          {
            :city_id => row['href'][/\d+/],
            :city_cn => row.text
          }
        }
      end
    end
  end
end
