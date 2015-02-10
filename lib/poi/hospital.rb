# Table to store the data of hospital
module Db
  class BasePoiHospital < ActiveRecord::Base
  end
end

# class Hospital
module POI
  class Hospital
    BASE_URL ='http://www.a-hospital.com'

    def initialize
      url = "#{BASE_URL}/w/%E5%85%A8%E5%9B%BD%E5%8C%BB%E9%99%A2%E5%88%97%E8%A1%A8"
      html = Nokogiri::HTML open(url)
      @provinces = html.xpath("//h3/span[@class='mw-headline' and text()!='']/..")
    end

    def provinces
      @provinces
    end

    def cities
      @cities = []
      @provinces.each { |prov|
        cities = prov.next_element.next_element.xpath("./a")
        cities.each do |city|
          @cities << { :province_name=>prov.text, :city_name=>city.text, :uri=>city['href'] }
        end
      }
      @cities
    end
    
    def hosps(city)
      url = "#{BASE_URL}#{city[:uri]}"
      html = Nokogiri::HTML open(url)
      hosp_list = html.xpath("//ul/li/b/a")
      hosps = hosp_list.collect do |hosp|
        self.fetch_info(hosp, city)  
      end
      hosps
    end

    def fetch_info(hosp, city)
      list = hosp.xpath("./../../ul/li")
      base_info  = { :name=>hosp.text, :province=>city[:province_name], :city=>city[:city_name] }
      #website = list.at("./b[text()='医院网站']/..")
      #base_info[:homepage] = website.nil? ? nil : website.text.tr('医院网站：','')
      intros = { :level=>'医院等级', :mode=>'经营方式', :dep=>'重点科室', :address=>'医院地址', :phone=>'联系电话' }
      intros.update(intros) do |key, val| 
        item  =  list.at("./b[text()='#{val}']/../text()")
        item.nil? ? nil : item.to_s.tr('：','')
      end
      base_info.merge(intros)
    end 

   # log msg
    def log(msg)
      log_file = File.open("hospital.log", "a+")
      log_file.syswrite(msg)
      log_file.close
    end

    def producer(city_id, pipeline, redis)
      timer = Time.now 
      self.cities.drop(city_id).each do |city|
        sleep(2)    # Sleep for 2 second, change it if necessary
        puts "Fetching hospitals of city: #{city[:province_name]}#{city[:city_name]} "
        limiter = 0
        begin
          hospitals = self.hosps(city)
          hospitals.each do |hosp|
            pipeline.push(hosp)
          end
          puts "\e[32mfinished!\e[0m"
        # Exception handler
        rescue =>e
          limiter+=1
          retry if limiter<3
          p e
          warn "\e[31mError encountered when processing city: #{city[:city_name]}\e[0m"
          case e
            when OpenURI::HTTPError
              if e.message=="404 Not Found"
                next
              else
                msg = %Q(#{Time.now} #{e} finished: #{city_id}, unfinished: #{ @cities.size-city_id }, Timeleft: #{((Time.now-timer)*city_id/@cities.size).to_i} seconds.\n)
                self.log(msg)
                redis.set('hospital_stuck', city_id)
                exit
              end
            else
              self.log(%Q(#{Time.now} #{e} \n))
          end
        end
        city_id+=1
      end
      redis.set('hospital_stuck', 0)
      abort "\e[32m Works finished!\e[0m" 
    end

    def consumer(pipeline)
      # Wait for producer
      sleep(2)
      while true
        begin
          item = pipeline.pop
          existed_item = Db::BasePoiHospital.find_by(name: item[:name], city: item[:city])
          existed_item.nil? ? Db::BasePoiHospital.new(item).save : existed_item.update(item)
          # adaptive wrting rate
          sleep(1.0/(pipeline.length+1))
        rescue => e
          p e
          self.log(%Q(#{Time.now} #{e}\n))
        end
      end
    end

  end
end