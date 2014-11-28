module POI
  class Venue

    extend POI

    def self.get_max_page_num()
      url = "http://venue.damai.cn/search.aspx?cityID=0&k=0&keyword=&pageIndex=1"
      html =  request( url )
      span = html.match(/<span class="ml10">.*?<\/span>/).to_s
      span.match(/>.*?</).to_s.match(/\d{2,}/).to_s.to_i
    end

    def self.urls_in_page( page_i )
      url = "http://venue.damai.cn/search.aspx?cityID=0&k=0&keyword=&pageIndex=#{page_i}"
      page = Nokogiri::HTML( request( url ) )
      page.search("li[@class='clear']").each do |li|
        # deal with li
      end
    end

    def self.get_info( url )
    end

  end # Venue
end # POI
