require 'httparty'
class_files = %w( landmark/meituan     landmark/baidu_waimai 
                  landmark/dianping    landmark/elong_flight
                  landmark/train       landmark/metro 
                  landmark/scene       landmark/university
                  landmark/consulate   landmark/embassy
                  landmark/baidu_lvyou landmark/tongcheng
                  landmark/institution landmark/court
                  landmark/bus_station landmark/zhuna)

class_files.each { |file| require_relative file }
module Db
  class BasePoiLandmark < ActiveRecord::Base
  end
  class BaseElongHotelCity < ActiveRecord::Base
  end
end

module POI
  module LandMark
    class Worker
      REGEX = /\s+|( +)|( +)/
      Keys  = %w(nML7mZ3xMUkAPjz3KAWQCq3j B76dd0064529522a1a9bedadbfaf48f6 57e45E513cb63ccc69895779634be327  
                 aQx1gGYrQGqIrUAozPHlUDAC ZfGRFj1029I1lkZrTSPFbCIW  E3m8XYAayQY0Z0Rm32zaNZmq SWnBEi8yt4klHKPHFzi5Xuvm  
                 A5KusGlYIoejSBgLpgIO4ypH GG4XEskQdLZTT4ADvOjYcDmV PH5XOjTkT20Yx7YNtjczLyE3 ITRp7wngpB1aulNFgoryaRGG
                 uZIOFIRWBLptE04mHwNrMcAj N4BeVM6t7LTjjbDXHbDMMZkx Tlyg0gekTuqpUH6bMPLcsth9 2Rei7o9gbdqRLSGXeMHj5DNX
                 L7oWwVgcqzz9ZTGsfwlftI0o)
                
       CP  = {
          :meituan       => MeiTuan,
          :wm_baidu      => BaiduWaimai,
          :dianping      => DianPing,
          :elong_flight  => ElongFlight,
          :train         => Train,
          :metro         => Metro,
          :scene         => Scene,
          :university    => University,
          :consulate     => Consulate,
          :embassy       => Embassy,
          :ly_baidu      => BaiduLvyou,
          :institution   => Institution,
          :tongcheng     => TongCheng,
          :court         => Court,
          :bus_station   => BusStation,
          :hospital      => POI::Hospital,
          :high_school   => POI::School::High,
          :middle_school => POI::School::Middle,
          :expo          => POI::ExpoCenter,
          :venue         => POI::Venue,
          :elementary_school=> POI::School::Elementary,
          :zhuna         => Zhuna,
        }

      def initialize(web_site) 
        @idx_of_keys  =  0
        @counter      =  0
        @redis        =  Redis.new(:host=>"test1", :port=>6379)
        @key          =  web_site
        @pipe         =  Queue.new
        @geocoder     =  Baidumap::Request::Geocoder.new(Keys[@idx_of_keys])
        @crawler      =  CP[@key.to_sym].new
        @landmarks    =  Db::BasePoiLandmark
        @elong_cities =  Db::BaseElongHotelCity
      end 

      def producer
        Thread.new {

          city_list   = @crawler.city_list 

            @start    = get_rd(@key)
            city_list.drop(@start).each do |city|

            city_cn     = city[:city_cn]
puts "A" + city_cn
#            @elong_city = @elong_cities.find_by(NameShort: city_cn)
#@elong_city = @elong_cities.find(NameShort: city_cn)
puts "B" + city_cn
            pois        = @crawler.landmarks(city)
puts pois
            pois.each do |name, city_info|
              begin
                addrs = {}
                addrs = location(name, city_info)
  
                redo if addrs.nil?
                @pipe << {
                  :name          => name.gsub(REGEX,''),
                  :elong_city_id => @elong_city.nil? ? '0000' : @elong_city[:Code],
                }.merge(city_info).merge(addrs)
              rescue TypeError=>e
                puts e
                warn "#{e.class} #{e.message} #{e.backtrace.join("\n")}"
                next
              end
            end
            @counter+=1
          end
        }

      end

      def consumer 
        Thread.new {
#          while @pipe.size>0 or @pduer.status do 
while Thread.list.size > 2 do 
  #puts "test" + @pipe.size.to_s
  if @pipe.size > 0 
            row     =  @pipe.pop
            puts 0
            puts ENV["ELONG_ENV"]
	    puts "Inserting #{row[:name]}..."
            existed = @landmarks.find_by(name: row[:name],city_cn: row[:city_cn],source_domain: row[:source_domain])
            p 1
	    p existed
            p 2
            #existed.nil? ? @landmarks.new(row).save : existed.update(row)
            if existed.nil?
              land = @landmarks.new(row)
              p land
              p 3
              land.save
              p 4
            else
              existed.update(row)
              p 5
            end
            
  puts "Inserting complete"
  end
            sleep(1/(@pipe.size+1))
          end
        }
      end

      def work
        begin 
          @pduer  = producer
          @writer = consumer

  #          @pduer.join


   #         @writer.join

while Thread.list.size > 1 do 
  sleep(1)
end
        rescue Exception=>e
p e
          error_handler e 
        end
        set_rd(@key)
        puts "\e[32m Congratulation! All things Finished.\e[0m"
      end 

      def location(name, city_info)
        city      = city_info[:city_cn]
        addr_dtls = {:lng=>nil,:lat=>nil,:address=>nil,:province=>nil}
        addr_arg  = city || city_info[:province]
        geo_crd   = @geocoder.encode(name, addr_arg).result

        if geo_crd.nil?
          @geocoder = chg_api_key  # change baidumap api keys if quotas runs out
          return
        elsif !geo_crd.empty?
          lng_lat   = geo_crd['location']
          geo_dtls  = @geocoder.decode(lng_lat['lat'],lng_lat['lng']).result

          if same_city?(geo_dtls, city)
            addr_dtls = {
              :lng      => lng_lat['lng'],
              :lat      => lng_lat['lat'],
              :city_cn  => geo_dtls['addressComponent']['city'].gsub(/市$/,''),
              :address  => geo_dtls['formatted_address'],
              :province => geo_dtls['addressComponent']['province'],
            }
          end
        end
        @elong_city = @elong_cities.find_by(NameShort: addr_dtls[:city_cn]) unless city
        addr_dtls
      end
       
      def chg_api_key
        @idx_of_keys+=1
        raise "No more keys remains." if @idx_of_keys>=Keys.length
        @geocoder = Baidumap::Request::Geocoder.new(Keys[@idx_of_keys])
      end

      def same_city?(geo_dtls, city)
        addr  = geo_dtls['addressComponent']
        [addr['city'], addr['district']].any? { |ad| city.nil? or ad.include?(city.to_s) }

      end
     
      def error_handler(e)
        set_rd(@key,@counter+@start)
        raise e 
      end

      def get_rd(key, init_value=0)
        value = @redis.get(key)
        value.nil? ? init_value : value.to_i
      end

      def set_rd(key,value=0)
        @redis.set(key,value)
      end

    end
  end
end
