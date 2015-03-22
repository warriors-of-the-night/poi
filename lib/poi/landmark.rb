require 'httparty'
require 'ruby-pinyin'
require_relative 'landmark/meituan'
require_relative 'landmark/baidu_waimai'
module POI
  module LandMark
  	CP = {:meituan => MeiTuan, :baidu_waimai => BaiduWaimai}
    PIPE = Queue.new
    def self.producer(web_site)
      Thread.new {
        crawler   = CP[web_site.to_sym].new
        city_list = crawler.city_list
        city_list.each  do |city|
          crawler.landmarks(city).each do |name, city_info|
          PIPE <<  {:name =>name.to_s, :cp=>web_site}.merge(city_info)
          end
        end
      }
    end

    def self.consumer 
      Thread.new { 
        while @pduer.status or PIPE.length>0 do 
          item =  PIPE.pop
          puts item
        end
      }
    end

    def self.work(web_site)
      @pduer  = producer(web_site)
      @writer = consumer
      @pduer.join
      @writer.join
    end 
  end
end
