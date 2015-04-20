module POI
  module LandMark
    class TongCheng

      def initialize
        @city_list_url = "http://www.ly.com/scenery/sceneysearchbycity.html"
      end
      
      def landmarks(city)
        lms = {}
        url = "http://www.ly.com/scenery/SearchList.aspx?&action=getlist&page=1&pid=#{city[:city_id]}&cid=#{city[:cid]}" 
        @page = Nokogiri::HTML HTTParty.get(url).body
        1.upto(pg_nm).each { |pg_id|
          unless pg_id==1
            url   = "http://www.ly.com/scenery/SearchList.aspx?&action=getlist&page=#{pg_id}&pid=#{city[:city_id]}&cid=#{city[:cid]}" 
            @page = Nokogiri::HTML HTTParty.get(url).body
          end
          @page.search('div.scenery_list > div > div.img_con > a').each do |scene|
            name = scene['title']
            lms[name] = {
              :cata         => 'scene',
              :city_cn      => city[:city_cn],
              :source_domain=> 'ly.com',
            }
          end
        } 
        lms      
      end

      def city_list
        municipality = ['北京','上海','天津','重庆']
        page_html    = Nokogiri::HTML HTTParty.get(@city_list_url).body
        cities       = page_html.search('div#tab02 dl > dd > a')
        cities.map do |city|
          href       = city['href']
          str_split  = href.split('_')
          name       = city.text.strip
          { 
            :href    => href,
            :city_id => str_split[1],
            :city_cn => name,
            :cid     => municipality.include?(name) ? 0 : str_split[2],
          }
        end
      end

      def pg_nm
        pg_num = @page.at('//input[@id="txt_AllpageNumber"]')
        pg_num.nil? ? 1 : pg_num['value'].to_i
      end

      def html
        @page.to_html
      end
    end
  end
end
