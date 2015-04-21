module POI
  module LandMark
    class Institution

      def initialize
        @hg_url = "http://c.wanfangdata.com.cn/Institution.aspx"
      end

      def landmarks(city)
        @html = Nokogiri::HTML HTTParty.get(city[:uri]).body
        lms   = {}
        1.upto(pg_num).each { |pg_id|
          unless pg_id==1
            url   = city[:uri]+"&p=#{pg_id}"
            @html = Nokogiri::HTML HTTParty.get(url).body 
          end
          list = @html.search('li[@class="title_li"]/a[2]').each do |a|
            name      = a.text.strip
            lms[name] = {
              :cata          => 'institution',
              :source_domain => 'wanfangdata.com.cn',
              :province      =>  city[:province]
            }
          end 
        }
        lms
      end

      def city_list
        html = Nokogiri::HTML HTTParty.get(@hg_url).body
        pois = html.search('div#csiPanel > div > ul.diqu_ul > li > a')
        pois.map { |poi|
          {
            :uri      => poi['href'],
            :province => pois.text.strip,
          }
        }
      end
      
      def pg_num
        page_header = @html.at_css('span#ctl00_ContentPlaceHolder1_ctl03_PagerControl1')
        page_header.text[/\d+/]
      end

    end
  end
end
