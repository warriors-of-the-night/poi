module POI
  class Dianping
    extend POI

   # City list from `http://www.dianping.com/citylist`
    def self.cities
      web_page = Nokogiri::HTML(open(URI('http://www.dianping.com/citylist')))
      internal_cities = web_page.at("//ul[@class='glossary-list gl-region Hide']")
      city_set = []
      internal_cities.search("a").each { |city|
        city_set << {:city_en => city.text, :url => city['href']} if city.text!="更多"
       }
      city_set
    end

    # Fetching pois of each city_id
    def self.pois(city_id)
      url = "http://www.dianping.com/shopall/#{city_id}/0"
      web_page = Nokogiri::HTML open URI(url)

      # Exception will be raised if bad Argument
      raise ArgumentError, "Bad Argument" if web_page.at("//div[@class='aboutBox errorMessage']")

      title = web_page.at("//h1[@class='shopall']/strong")
      # City_name
      if title
        title = title.text
        title.slice!('生活指南地图')      
      end
      mapping = { 'center' => '商区', 'landmark' => '地标', 'metro' => '地铁沿线' }
      pois = []
      # Business centers, landmarks and metro
      mapping.each do |type, word| 
        pois_html = web_page.xpath("//h2[text()='"+"#{word}']/..").search("a[@class='B']")
        pois_html.each { |item|
          uri_split = item['href'].split('/')    # An example of href just like "/search/category/4/0/r13880"
          pois << {:name => item.text,  :cata => type, :center_id => uri_split[-1], :city_id => uri_split[-3],:city_name => title }
        }
      end
      pois
    end
  end
end
