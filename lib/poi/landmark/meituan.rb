module POI
  module LandMark
    class MeiTuan
      def initialize
        @base_url = 'http://www.meituan.com/sitemap/dealsitemap.php' 
        @options  = {:headers => {"User-Agent" => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.73.11 (KHTML, like Gecko) Version/7.0.1 Safari/537.73.11'}
          }      
      end

      def landmarks(city)
        @page =  Nokogiri::HTML HTTParty.get("#{@base_url}?cityid=#{city[:city_id]}", @options)
        collections = {}
        page_number.times do |page_id|
          unless page_id==0
            url   =  "#{@base_url}?cityid=#{city[:city_id]}&page=#{page_id+1}"
            @page =  Nokogiri::HTML HTTParty.get(url, @options)
          end
          @page.search('//body/li').each do |li|
            li.at_css('a').text.gsub(/】|【/,'').split('/').each { |name|
              collections[name] = {:source_domain =>'meituan.com',:cata=>'center'}.merge(city) if !collections.has_key?('name')
            }
          end
        end
        collections
      end
  
      def page_number
        last_page = @page.at('//ul[@class="paginator"]/li[@class="last"]/a')
        last_page.nil? ? 0 : last_page['href'][/(?<=page=)\d+/].to_i
      end

    
      def city_list
        html = Nokogiri::HTML HTTParty.get('http://www.meituan.com/sitemap/citysitemap.php', @options)
        city_list_html = html.search('//body/li/a')

        @city_list = city_list_html.map do |city|
          city_cn  = city.text.gsub(/网页地图/,'')
        # city_en  = PinYin.sentence(city_cn).gsub(/\s/,'')
          {
            :city_id => city['href'][/\d+/], 
          # :city_en => city_en, 
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

