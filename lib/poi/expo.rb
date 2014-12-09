module POI
  class Expo

    extend ::POI

    def self.get_info( expo )
      """
      @Input: expo with it url indicated by expo[:page]
      @Output: expo with detail added
      """
      url = expo[:page]
      # use customized request instead of open
      doc = Nokogiri::HTML( request( url ) )

      # get exi center orgainzor and offcial_site
      info = doc.search("div[@class='exhinfo_center']").search('li')
      info.each do |text|
        text = text.text.rstrip
        if text[0..3] == '展会场馆'
          expo[:location] = text[ 5..-1 ]
        elsif text[0..3] == '组织单位'
          expo[:organizor] = text[ 5..-1 ]
        elsif text[0..3] == '官方网站'
          expo[:official_site] = text[ 5..-1 ]
        end
      end
      
      # get range
      info = doc.search("div[@class='box exh_box']")
      info.each do |x|
        if x.search("h3").text == "展品范围"
          expo[:range] = x.search("div[@class='box-bd exhdetail']").text
        elsif x.search("h3").text == "联系信息"
          expo[:contact] = x.search("div[@class='box-bd exhdetail']").text
        end
      end
      return expo
    end

    def self.get_expos()
      url = "http://www.haozhanhui.com/zhanlanjihua/"
      doc = Nokogiri::HTML(open(url))

      table = doc.search("ul[@class='trade-news haiwai']")
      
      expos = []
      # get date, city and catagory
      table.search("li").each  do |li|
        text = li.text

        expo = {}
        expo[:date] = text[0,10]
        expo[:name] = text.match(/】\S\S([0-9]+|[a-zA-Z]+).+/).to_s[3..-1]

        # Deprecatem, we don't need city info now
        # text.gsub(/【.*?】/).each do |x|
        #   if expo[:cata] == ''
        #     expo[:cata] = x[1,x.length-2] 
        #     continue
        #   end
        #   expo[:city] = x[1,x.length-2] 
        # end
        # get info page
        expo[:page] = li.search("a").attribute("href").value

        expos << expo
      end
      return expos
    end

  end
end
