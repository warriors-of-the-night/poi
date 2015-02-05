module Db
  class BasePoiEncyclopedia < ActiveRecord::Base
  end
  class DianpingPoi < ActiveRecord::Base
  end
end

module POI
  class Encyclopedia
    BASE_URL = 'http://www.baike.com/wiki/'
  
   # Encyclopedia content of landmark
    def content(landmark)
      @html = Nokogiri::HTML open(self.url(BASE_URL, landmark))
      @content = @html.at("//div[@class='summary']/p")
      @content.nil? ? nil : @content.text
    end

    # Fetch the first result if content return nil
    def attemp(landmark)
      base_uri = 'http://so.baike.com/s/doc/' 
      @html = Nokogiri::HTML open(self.url(base_uri, landmark))
      @content = @html.at("//div[@class='result-list']/p")
      @content.nil? ? nil : @content.text
    end

   # Fetch landmark from database and call function `content` to crawl encyclopedia content 
    def process
      begin
        timer = Time.now
        counter = 0
        dp_landmarks = Db::DianpingPoi.where(cata: 'landmark')
        dp_landmarks.find_each do |landmark|
          sleep(2)
          counter+=1
          puts "Encyclopedia content of #{landmark[:name]}"
          content = self.content(landmark[:name]) || self.attemp(landmark[:name])
          if content.nil? 
             puts "\e[31m Return nil\e[0m" 
          else
             puts "\e[32m Content: #{content[0..20]}...\e[0m"
          end
          encyclopedia_item = {
              :name=>landmark[:name], 
              :city=>landmark[:city_name],
              :content=>content
            }
        self.insert(encyclopedia_item)
        end
      rescue =>e
        msg = %Q(#{Time.now}  #{e} finished: #{counter} , unfinished: #{ dp_landmarks.size-counter }, Timeleft: #{(Time.now-timer)*counter/dp_landmarks.size}\n)
        self.log(msg)
        exit
      end
    end

   # Insert each item to database
    def insert(item)
      existed = Db::BasePoiEncyclopedia.find_by(name: item[:name], city: item[:city])
      existed.nil? ? Db::BasePoiEncyclopedia.new(item).save : existed.update(item)
    end
    
   # Process the landmark as keyword ,for example:上海广场（原无限度）--> 上海广场,
   # Encode the url 
    def url(base_uri,landmark)
      landmark = landmark.gsub(/（.+）/,'')
      URI::encode "#{base_uri}#{landmark}"
    end

   # log msg
    def log(msg)
      log_file = File.open("encyclopedia.log", "a+")
      log_file.syswrite(msg)
      log_file.close
    end

  end
end