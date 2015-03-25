module POI
  module LandMark
    class DianPing    
			def initialize
        @options = {:headers => {"User-Agent" => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.73.11 (KHTML, like Gecko) Version/7.0.1 Safari/537.73.11'}
        }
			end
			
      # City list from `http://api.t.dianping.com/n/base/cities.xml`
      def city_list
        cities_xml = Nokogiri::XML(HTTParty.get('http://api.t.dianping.com/n/base/cities.xml', @options).body)
        cities     = cities_xml.xpath("//citys/city").map { |city|
          {
            :city_id => city.at('id').text,
            :city_cn => city.at('name').text,
           #:city_en => city.at('enname').text,
          } 
        }
      end

      # Fetching pois of each city
      def landmarks(city)
        url       = "http://www.dianping.com/shopall/#{city[:city_id]}/0"
        @web_page =  Nokogiri::HTML HTTParty.get(url, @options)

        # Exception will be raised if bad Argument
        raise ArgumentError, "Bad Argument" if @web_page.at("//div[@class='aboutBox errorMessage']")

        title    = @web_page.at("//h1[@class='shopall']/strong")
        # City_name
        title    = title.text.slice!('生活指南地图') if title
        mapping  = { 'center' => '商区', 'landmark' => '地标', 'metro' => '地铁沿线' }
        pois     = {}
        # Business centers, landmarks and metros
        mapping.each do |type, word| 
          pois_html = @web_page.xpath("//h2[text()='"+"#{word}']/..").search("a[@class='B']")
          pois_html.each { |poi|
           # uri_split = poi['href'].split('/')    # An example of href just like "/search/category/4/0/r13880"
            poi.text.split('/').each do |name|
            pois[name]   = {  
              :cata          => type,
              :source_domain => 'dianping.com',
            # :center_id => uri_split[-1],
            }.merge(city)
            end
          }
        end
        pois
      end

      def html
        @web_page.to_html
      end
=begin
   # log msg
    def log(msg)
      log_file = File.open("dianping.log", "a+")
      log_file.syswrite(msg)
      log_file.close
    end

    def producer(city_id, pipeline, redis)
      city_num  = self.cities.size
      timer = Time.now 
      until city_id > city_num do
          # Sleep for 2 second
          sleep(2)
          limiter = 0
          begin
            pois = self.pois(city_id)
            pois.each do |poi|
              pipeline.push(poi)
            end
            puts "Processing city_id: #{city_id} finished!"

          # Exception handler
          rescue =>e
            limiter+=1
            retry if limiter<3
            p e
            warn "\e[31mError encountered when processing city_id: #{city_id}\e[0m"
            case e
              when ArgumentError
                msg = %Q(#{Time.now} #{e} when visiting http://www.dianping.com/shopall/#{city_id}/0".\n)
                self.log(msg)
                city_num+=1
              when Errno
                next
              when OpenURI::HTTPError
                redis.set('city_stuck', city_id)
                msg = %Q(#{Time.now} #{e} finished: #{city_id}, unfinished: #{ city_num-city_id }, Timeleft: #{((Time.now-timer)*city_num/city_id).to_i} seconds.\n)
                self.log(msg)
                exit
              else
                exit
            end
          end
          city_id+=1
        end
      redis.set('city_stuck', 1)
      abort "\e[32m Works finished!\e[0m"
    end

    def consumer(pipeline)
      # Wait for producer
      sleep(2)
      while true
        begin
          item = pipeline.pop
          existed_item = Db::BasePoiLandmark.find_by(center_id: item[:center_id], city_id: item[:city_id], name: item[:name])
          existed_item.nil? ? Db::BasePoiLandmark.new(item).save : existed_item.update(item)
          # adaptive wrting rate
          sleep(1.0/(pipeline.length+1))
        rescue => e
          p e
         self.log(%Q(#{Time.now} #{e}\n))
        end
      end
    end
=end
    end
  end
end
