module Db
  class BasePoiEncyclopedia < ActiveRecord::Base
  end
  class DianpingPoi < ActiveRecord::Base
  end
end

module POI
  class Encyclopedia
    BASE_URL = 'http://www.baike.com/wiki/'
   # Extract text from content
    def extract(doc=nil)
      return "" if doc.nil?
      doc.traverse { |node|  node.text.gsub(/\s|　/, "") }
    end

   # Insert each item to database
    def insert(item)
      existed = Db::BasePoiEncyclopedia.find_by(name: item[:name], city: item[:city])
      existed.nil? ? Db::BasePoiEncyclopedia.new(item).save : existed.update(item)
    end
    
   # Process the landmark as keyword,for example:上海广场（原无限度）--> 上海广场,
   # Encode the url 
    def url(landmark)
      landmark = landmark.gsub(/（.+）/,'')
      URI::encode "#{BASE_URL}#{landmark}"
    end

   # Log msg
    def log(msg)
      log_file = File.open("encyclopedia.log", "a+")
      log_file.syswrite(msg)
      log_file.close
    end

   # Encyclopedia content of landmark
    def content(landmark)
      @html    = Nokogiri::HTML open(self.url(landmark))
      @content = @html.at("//div[@id='content']")
      return nil if @content.nil?
      @summary = @html.at("//div[@class='summary']/p[text()!='']")
      if @summary.nil? or @summary.text.strip.size<100
        content_h2 = ''
        @content.search("p[text()!='']").each do |para|      
          content_h2 = self.extract(para)
          break if content_h2.size > 50
        end
        if content_h2==''
          @html.xpath("//div[@id='content']/text()").each do |para|
            content_h2 = para.text
            break if content_h2.size > 50
          end
        end
        self.extract(@summary)+content_h2
      else
        self.extract(@summary)
      end
    end
    
   # Fetch landmark from database and call function `content` to crawl encyclopedia content 
    def process
      begin
        timer        = Time.now
        counter      = 0
        dp_landmarks = Db::DianpingPoi.where(cata: 'landmark')
        dp_landmarks.find_each do |landmark|
          sleep(3*rand(0.0..1.0))  # change this if necessary
          counter+=1
          puts "Encyclopedia content of #{landmark[:name]}"
          content = self.content(landmark[:name]) || self.content("#{landmark[:city_name]}#{landmark[:name]}")
          if content.nil? 
             puts "\e[31m Return nil\e[0m" 
          else
             puts "\e[32m Content: #{content[0..20]}...\e[0m"
          end
          encyclopedia_item =  {
              :name         => landmark[:name], 
              :city         => landmark[:city_name],
              :content      => content
            }
        self.insert(encyclopedia_item)
        end
      rescue => e
        msg  = %Q(#{Time.now} #{e} finished: #{counter}, unfinished: #{ dp_landmarks.size-counter }, Timeleft: #{((Time.now-timer)*dp_landmarks.size/counter).to_i} seconds.\n)
        self.log(msg)
        exit
      end
    end

   # Html content for debug reason
    def html
      @html.to_html
    end
  end
end
