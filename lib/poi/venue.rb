# -*- coding: utf-8 -*-
module POI
  class Venue

    extend POI

    def self.max_page_num()
      url = "http://venue.damai.cn/search.aspx?cityID=0&k=0&keyword=&pageIndex=1"
      html =  request( url )
      span = html.match(/<span class="ml10">.*?<\/span>/).to_s
      span.match(/>.*?</).to_s.match(/\d{2,}/).to_s.to_i
    end

    def self.venues_in_page( page_i )
      url = "http://venue.damai.cn/search.aspx?cityID=0&k=0&keyword=&pageIndex=#{page_i}"
      page = Nokogiri::HTML( request( url ) )

      venues = []
      page.search("li[@class='clear']").each do |li|
        venue = {}

        title = li.search("h3").text.force_encoding('utf-8')
        venue[:name] = title.match('.{1,}\[').to_s[0..-2]

        city_region = title.match('\[.*?\]').to_s[1..-2]
        venue[:city] = city_region.match('.{1,}-').to_s[0..-2]
        venue[:region] = city_region.match('-.{1,}').to_s[1..-1]

        li.search("p[@class='text']").each do |p|
          if p.text.start_with?('场馆地址：')
            venue[:address] = text[5..-1]
          end
        end 

        venues << venue
      end
      venues
    end

    def self.get_info( venue )
      page = Nokogiri::HTML( request( venue[:page] ) )
      venue[:intro] = page.search("div[@class='info']").search("div[@id='agree']").text
      venue[:facilities] = page.search("div[@class='venueBox  facilities']").search("div[@class='in']").text
      return venue
    end

  end # Venue
end # POI
