module POI
  class BusinessCenter
    extend POI

  # City list from `http://www.dianping.com/citylist`
    def self.cities
      the_page = Nokogiri::HTML(open(URI('http://www.dianping.com/citylist')))
      internal_cities = the_page.search("//ul[@class='glossary-list gl-region Hide']")[0]
      city_set = []
      internal_cities.search("a").each { |city|
        city_set << {:city_en=>city.text, :url=>city['href']} if city.text!="更多"
       }
      city_set
    end

    # Fetching business centers of each city_id
     def self.centers(city_id)
       url = "http://www.dianping.com/shopall/#{city_id}/0"
       the_page = Nokogiri::HTML open URI(url)
       business_centers = the_page.xpath("//h2[text()='商区']/..").search("a[@class='B']")
       return  business_centers.collect { |center|
          uri_split = center['href'].split('/')    # an example of href just like "/search/category/4/0/r13880"
          {:center_id=>uri_split[-1], :city_id=>uri_split[-3], :name=>center.text}
       }
      end

=begin
   # Fetching business centers of each city
    def self.centers(city)
      url = "http://www.dianping.com#{city}/food"
      page = Nokogiri::HTML(open URI(url))
      script_content = page.search("//script[@class='J_auto-load']").text
      business_centers = Nokogiri::HTML(script_content).search("//div[@class='fpp_business']/dl/dd/ul/li/a")
      return  business_centers.collect { |center|
        {:center_id=>center['href'].split('/')[-1], :city_id=>center['href'].split('/')[-3], :name=>center.text}
       }
    end
=end

  end
end
