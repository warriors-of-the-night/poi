module POI
  module LandMark
    class Court
      
      def initialize 
        @hg_url = "http://www.5827.net/city/"
      end

      def landmarks(city)
        lms   = {}
        @html = Nokogiri::HTML HTTParty.get(city[:uri]).body
        1.upto(pg_num).each { |pg_id|
          unless pg_id==1
            url   = "http://#{URI(city[:uri]).host}/fayuan_#{pg_id}"
            @html = Nokogiri::HTML HTTParty.get(url).body
          end
          pois = @html.search('//ul[@class="comlist"/li/div[@class="company"]/a').each { |poi|
            name = poi['title']
            lms[name] = {
              :cata          => 'court',
              :source_domain => '5827.net',
              :city_cn       => city[:name],
            }
          }
        }
        lms
      end

      def city_list
        cities = []
        provinces.each { |prov|
          if ['北京市','天津市','上海市','重庆市'].include?(prov[:name])
            cities << prov
          else
            pg = Nokogiri::HTML HTTParty.get(prov[:uri]).body
            pg.search("//div[@class='catlist mb10']/dl[1]/span/a").each do |city|
              cities << {
                :name   => city.text.strip,
                :uri    => city['href'],
              }
            end
          end
        }
        cities
      end

      def provinces
        @hp       = Nokogiri::HTML HTTParty.get(@hg_url).body
        div_prov  = @hp.search('div.dirlist > ul > li> div > a')
        div_prov.map { |prov|
          {
            :name    => prov.text.strip,
            :uri     => prov['href']+'fayuan',
          }
        }
      end
      
      def pg_num
        last_pg = @html.search('div[@class="pageLink"]/a')[-1]
        last_pg.nil? ? 1 : last_pg['href'][/\d+/].to_i 
      end
    end
  end
end
