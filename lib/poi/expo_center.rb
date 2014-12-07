module POI
  class ExpoCenter

    extend ::POI

    def self.get_expo_center_ids()
      page = Nokogiri::HTML( request('http://www.haozhanhui.com/exhplace.html') ) 
      province_pages = []
      page.search("div[@class='asfcz']").search("a").each do |x|
        province_pages << x.attribute("href").value
      end

      expo_center_ids = []
      province_pages.each do |province_page|
        page = Nokogiri::HTML( request( province_page ) )
        page.search("div[@class='right_center_zi']").search("a").each do |a|
          expo_center_ids << a.attribute('href').value.match(/\/\d{2,}.html/).to_s[1..-6]
        end
      end

      return expo_center_ids
    end

    def self.get_expo_center_info( id )
      center = {}
      center[:id] = id.to_i

      # get ciry, location, website, intro and contact
      url = "http://www.haozhanhui.com/place/place_detail_#{id}.html"
      center[:original_url] = url
      page = Nokogiri::HTML( request( url ) )
      page.search("div[@class='box exh_box']").each do |x|
        if x.search("h3").text[-4..-1] == "常用信息"
          # get name
          center[:name] = x.search("h3").text[0..-5]
          # get common info
          x.search("ul").search("li").each do |li|
            li = li.text
            if li[0..3] =="展馆城市"
              center[:city_name] = li[5..-1]
            elsif li[0..3] =="展馆位置"
              center[:address] = li[5..-1]
            elsif li[0..3] =="展馆网址"
              center[:website] = li[5..-1]
            end
          end
        elsif x.search("h3").text[-4..-1] == "展馆简介"
          center[:intro] = x.search("div[@class='box-bd placedetail']").text.strip
        elsif x.search("h3").text[-4..-1] == "联系信息"
          center[:contact] = x.search("div[@class='box-bd placedetail']").text.strip
        end
      end

      # check if has nearby info
      url = "http://www.haozhanhui.com/place/place_common_#{id}.html"
      page = Nokogiri::HTML( request( url ) )
      return center if page.search("div[@id='main']").search("div[@class='box-bd placecommon']").empty?
      
      # get nearby information
      # get bus information
      center[:bus] = get_expo_center_extra_info( '公交车站', id )

      # get tracffic information
      center[:traffic] = get_expo_center_extra_info( '路线图', id )

      # get bank information
      center[:bank] = get_expo_center_extra_info( '银行', id )

      # get extra infromation
      text = ''
      text += get_expo_center_extra_info( '购物', id )
      text += get_expo_center_extra_info( '餐厅', id )
      text += get_expo_center_extra_info( '娱乐休闲', id )
      center[:extra] = text

      return center
    end

    private
    def self.get_expo_center_extra_info( type, id )
      url = "http://www.haozhanhui.com/place/place_service_#{type}_#{id}.html"
      page = Nokogiri::HTML( request( url ))
      page.search("div[@class='box exh_box']")\
            .search("div[@class='box-bd placedetail']").text.strip
    end


  end
end
