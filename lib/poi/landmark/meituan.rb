module POI
  module LandMark
    class MeiTuan
      def initialize
        @base_url = 'http://www.meituan.com/sitemap/dealsitemap.php'       
      end

      def landmarks(city)
        @page =  Nokogiri::HTML HTTParty.get("#{@base_url}?cityid=#{city[:city_id]}")
        collections = {}
        page_number.times do |page_id|
          unless page_id==0
            url   =  "#{@base_url}?cityid=#{city[:city_id]}&page=#{page_id+1}"
            @page =  Nokogiri::HTML  HTTParty.get( URI url)
          end
          @page.search('//body/li').each do |li|
            mark = li.at_css('a').text
            mark.gsub(/】|【/,'').split('/').each { |item|
              collections[item] = city
            }
          end
        end
        collections
      end
  
      def page_number
        last_page = @page.at('//ul[@class="paginator"]/li[@class="last"]/a')
        last_page.nil? ? 0 : last_page['href'][/\d+/].to_i
      end

    
      def city_list
        html = Nokogiri::HTML HTTParty.get('http://www.meituan.com/sitemap/citysitemap.php')
        city_list_html = html.search('//body/li/a')

        @city_list = city_list_html.map do |city|
          city_cn  = city.text.gsub(/网页地图/,'')
          city_en  = PinYin.sentence(city_cn).gsub(/\s/,'')
          {
            :city_id => city['href'][/\d+/], 
            :city_en => city_en, 
            :city_cn => city_cn
          }
        end
      end

      def html
        @page.to_html
      end
    end
  end
end

