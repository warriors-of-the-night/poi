# Table to store the data of hospital
module Db
  class BasePoiHospital < ActiveRecord::Base
  end
end

# class Hospital
module POI
  class Hospital

    BASE_URL = 'http://www.a-hospital.com'

      Map    = {
        "hospital"        => "/w/全国医院列表",
        "plastic_surgery" => "/w/整形美容院列表",
        "gynecology"      => "/w/妇产科医院及儿童医院列表",
        "tumor_hospital"  => "/w/全国肿瘤医院列表",
        "ophthalmology"   => "/w/眼科医院列表",
    }      

     @type   = 'hospital'

    def self.type
      @type     
    end

    def initialize
      @type      = self.class.type
      @hg_url    =  "#{BASE_URL}#{Map[@type]}"
    end

    def provinces
      html    =  Nokogiri::HTML open(URI.encode(@hg_url))
      if @type=='hospital'
        provs =  html.xpath("//h3/span[@class='mw-headline' and text()!='']/..")
      else
        pois  = html.search('//div[@id="bodyContent"]/p[3]/a')
        provs =  []
        pois.each { |prov|
          provs << prov if !prov['class']
        }
      end
      provs
    end

    def landmarks(city)
      url  = "#{BASE_URL}#{city[:uri]}"
      html = Nokogiri::HTML open(url)
      hosp_list = html.xpath("//ul/li/b/a")
      hosps = {}
      hosp_list.each do |hosp|
        name = hosp.text
        hosps[name] = {
          :cata          => city[:cata],
          :city_cn       => city[:city_cn],
          :source_domain => 'a-hospital.com',
        }
      end
      hosps
    end

    def all_hosps
      cities = []
      provinces.each { |prov|
        pois = prov.next_element.next_element.xpath("./a")
        pois.each do |city|
          cities << {
            :province => prov.text, 
            :city_cn  => city.text.strip,
            :uri      => city['href'],
            :cata     => 'hospital',
          }
        end
      }
      cities
    end
    
    def category
      provinces.map { |prov|
        {
          :province  => prov.text.strip,
          :uri       => prov['href'],
          :cata      => @type,
        }
      }
    end

    def city_list
      @cities = @type=='hospital' ? all_hosps : category
    end
    
    def hosps(city)
      url = "#{BASE_URL}#{city[:uri]}"
      html = Nokogiri::HTML open(url)
      hosp_list = html.xpath("//ul/li/b/a")
      hosps = hosp_list.collect do |hosp|
        fetch_info(hosp, city)
      end
      hosps
    end

    def fetch_info(hosp, city)
      list = hosp.xpath("./../../ul/li")
      base_info  =  { 
        :name     => hosp.text, 
        :province => city[:province], 
        :city     => city[:city_cn] 
      }
      #website = list.at("./b[text()='医院网站']/..")
      #base_info[:homepage] = website.nil? ? nil : website.text.tr('医院网站：','')
      intros = { 
        :level   => '医院等级', 
        :mode    => '经营方式', 
        :dep     => '重点科室', 
        :address => '医院地址',
        :phone   => '联系电话' 
      }
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
      city_list.drop(city_id).each do |city|
        sleep(2)    # Sleep for 2 second, change it if necessary
        puts "Fetching hospitals of city: #{city[:province]}#{city[:city_cn]} "
        limiter = 0
        begin
          hospitals = hosps(city)
          hospitals.each do |hosp|
            pipeline.push(hosp)
          end
          puts "\e[32mfinished!\e[0m"
        # Exception handler
        rescue =>e
          limiter+=1
          retry if limiter<3
          case e
            when OpenURI::HTTPError
              msg = %Q(#{Time.now} #{e} finished: #{city_id}, 
                        unfinished: #{ @cities.size-city_id }, 
                        Timeleft: #{((Time.now-timer)*city_id/@cities.size).to_i} seconds.\n)
              log(msg)
              redis.set('hospital_stuck', city_id)
              exit
            else
              log(%Q(#{Time.now} #{e} \n))
          end
        end
        city_id+=1
      end
      redis.set('hospital_stuck', 0)
      abort "\e[32m Works finished!\e[0m" 
    end

    def consumer(pipeline)
      while true
        item = pipeline.pop
        existed_item = Db::BasePoiHospital.find_by(name: item[:name], city: item[:city])
        existed_item.nil? ? Db::BasePoiHospital.new(item).save : existed_item.update(item)
        sleep(1.0/(pipeline.length+1))
      end
    end

  end
end

%w(hospital/plastic_surgery_hospital.rb hospital/gynecology_hospital hospital/tumor_hospital).each do |file|
  require_relative(file)
end
