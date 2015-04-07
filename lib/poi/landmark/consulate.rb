module POI
  module LandMark
    class Consulate

      def landmarks(city)
        city_id = city[:id]
        if city_id>0
          @url = "http://www.fmprc.gov.cn/mfa_chn/fw_602278/lbfw_602290/lsgmd_602308/default_#{city_id}.shtml" 
        else
          @url = "http://www.fmprc.gov.cn/mfa_chn/fw_602278/lbfw_602290/lsgmd_602308/default.shtml"
        end
        @html  = Nokogiri::HTML HTTParty.get(@url).body
        lms    = {}
        pois   = @html.search('//div[@id="docMore"]/ul/li/a')
        pois.each {|poi|
          name = poi.text.to_s
          lms[name] = {
            :source_domain => 'fmprc.gov.cn',
            :cata          => 'consulate',
            :city_cn       => name[/(?<=驻).*(?=总领事馆)/]
          }
        }
        lms 
      end

      def city_list
        cities = [0,1,2,3,4].map{ |i|
          { :id =>i }
        }
      end
      
     def html 
       @html.to_html 
     end

    end
  end
end
