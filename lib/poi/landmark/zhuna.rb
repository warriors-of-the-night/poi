module POI
  module LandMark
    
    class Zhuna
      def initialize
        @base_url   = 'http://www.zhuna.cn'          
        @options = {:headers => {"User-Agent" => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.73.11 (KHTML, like Gecko) Version/7.0.1 Safari/537.73.11'}}
      end


      def city_list
        page = Nokogiri::HTML( HTTParty.get(@base_url + "/lable/",@options).body )
        cities = []
        
        page.search("div[@class='sitedh_nr']").search("dd").each do |dd|
          dd.search("a").each do |citylink|
            cities << {
              :city_cn   => citylink.content,
              :url    => citylink.attribute('href').value,
            }
#break
          end
        end
        cities
      end


      def landmarks(city)
        pois = {}

        page1 = Nokogiri::HTML( HTTParty.get(@base_url + city[:url],@options).body )
        page1.search("div[@class='sitecity_fj']").search("div[@class='sitecity_fjbt']").each do |level1|
          level1.search("a").each do |level1_a|

            attractionType = level1_a.content
            type = 'others'
            if attractionType == '旅游景点'
              type = 'attraction'
            elsif attractionType == '交通枢纽'
              type = 'hub'
            elsif attractionType == '文化教育'
              type = 'education'
            elsif attractionType == '医疗卫生'
              type = 'hospital'
            elsif attractionType == '会展场馆'
              type = 'venue'
            elsif attractionType == '交通设施'
              type = 'facilities'
            elsif attractionType == '商务大厦'
              type = 'office'
            elsif attractionType == '政府机构'
              type = 'institution'
            elsif attractionType == '地产小区'
              type = 'residential'
            elsif attractionType == '运动场馆'
              type = 'venue'
            elsif attractionType == '休闲娱乐'
              type = 'recreation'
            end

            page2 = Nokogiri::HTML( HTTParty.get(@base_url + level1_a.attribute('href').value,@options).body )
            page2.search("div[@class='sitecity_fj']").search("div[@class='sitecity_fjbt']").each do |level2|
              level2.search("a").each do |level2_a|
                page_base_url = level2_a.attribute('href').value[0,level2_a.attribute('href').value.length - 2]
                page_no = 1
                while true
                  page3 = Nokogiri::HTML( HTTParty.get("#{@base_url}#{page_base_url}#{page_no}",@options).body )

                  if page3.search("//ul[@class='sitecity_fjlist sitehotel_nr']").count > 0
                    page3.search("//ul[@class='sitecity_fjlist sitehotel_nr']").search("li").search("a").each do |mark|
                      pois[mark.content] = {
                        :city_cn       => city[:city_cn],
                        :cata          => type,
                        :source_domain => 'zhuna.com',
                      }
                      
                      puts mark.content
 break
                    end
                  else
                    break
                  end
                  page_no += 1
break
                end
              end
            end
          end
        end

        pois
      end
    end
  end
end

