require 'httparty'
require_relative 'landmark/meituan'
require_relative 'landmark/baidu_waimai'
require_relative 'landmark/dianping'
module Db
  class BasePoiLandmark < ActiveRecord::Base

  end
  class BaseElongHotelCity < ActiveRecord::Base

  end
end
module POI
  module LandMark
  	CP = {:meituan => MeiTuan, :baidu_waimai => BaiduWaimai, :dianping=>DianPing}
    def self.producer(web_site, ak)
      Thread.new {
        begin
          crawler   = CP[web_site.to_sym].new
          city_list = crawler.city_list
          geocoder  = Baidumap::Request::Geocoder.new(ak)
          city_list.each  do |city|
            elong_city = Db::BaseElongHotelCity.find_by(NameShort: city[:city_cn])
            crawler.landmarks(city).each do |name, city_info|
              geo_coordinate  = geocoder.encode(name, city_info[:city_cn]).result
              if geo_coordinate.empty?
                lng_lat, geo_details = {}, {'addressComponent'=>{}}
              else
                lng_lat     = geo_coordinate['location']
                geo_details = geocoder.decode(lng_lat['lat'],lng_lat['lng']).result
              end
              @pipe<<{
                :name          => name,
                :elong_city_id => elong_city.nil? ? '0' : elong_city[:Code],
                :lng           => lng_lat['lng'],
                :lat           => lng_lat['lat'],
                :province      => geo_details['addressComponent']['province'],
                :address       => geo_details['formatted_address'],
              }.merge(city_info)
            end
          end
        rescue=>e
          p e
          next
        end
      }
    end

    def self.consumer 
      Thread.new {
        while @pduer.status or @pipe.length>0 do 
          item =  @pipe.pop
          puts item
          existed = Db::BasePoiLandmark.find_by(name: item[:name], city_cn: item[:city_cn], source_domain: item[:source_domain])
          existed.nil? ? Db::BasePoiLandmark.new(item).save : existed.update(item)
          puts "\e[32m OK, finished!\e[0m"
          sleep(1/(@pipe.length+1))
        end
      }
    end

    def self.work(web_site, ak)
      @pipe   = Queue.new
      @pduer  = producer(web_site, ak)
      @writer = consumer
      @pduer.join
      @writer.join
    end 
  end
end
