module POI
  class School
    
    extend POI
    Mp = { 'mainxx' => 'elementary_school', 'maincz' => 'middle_school','main' => 'high_school'}
    def self.max_page_num( type = @type )
      url ="http://xuexiao.eol.cn/iframe/#{type}.php?page=1"
      html = request( url ) 
      html.force_encoding('utf-8')
      page = Nokogiri::HTML( html )
      page.search("center").text[-8..-1].match('\d{2,}').to_s.to_i
    end

    def self.schools_in_page( page_i, type = @type )
      url ="http://xuexiao.eol.cn/iframe/#{type}.php?page=#{page_i.to_s}"
     #html = request( url )
      html = HTTParty.get(url).body
      page = Nokogiri::HTML( html )

      schools = []
      page.search("div[@class='list_sjk']").each do |div|
        school = {}        
      # h1 = div.search('h1') + div.search('h5')
        h1 = div.at_css('h1') || div.at_css('h5')
        school[:name] = h1.text.strip

        begin
          school[:page] = h1.search('a').attribute('href').value + "index.html"
        rescue
        end

        begin
          school[:address] = div.search('h4').search('a').attribute('title').value
        rescue =>e
          school[:address] = div.search('h4').text[5..-1]
        end

        schools << school
      end
    
      return schools
    end
    
    def landmarks(city)
      schools = self.class.schools_in_page(city[:page_id])
      lms = {}
      schools.each do |school|
        lms[school[:name]] = {
          :cata          => self.class.type,
          :source_domain => 'xuexiao.eol.cn',
          :address       => school[:address].strip,
        }
      end
      lms
    end

    def city_list
      pg_nm = self.class.max_page_num 
      1.upto(pg_nm).map { |i|
        { :page_id => i}
      }
    end

    def self.type
      Mp[@type]
    end

    # deprecated, we do not need to enter the info page to get the address now
    def self.get_info( school )
      if school[:page] # if have info page crawl info there else do nothing
        html = request( school[:page] )
        page = Nokogiri::HTML( html )

        table = page.search("table[@class='line_22']")
        table.search('td').each do |line0|
          line = line0.text
          p line
          if line[0,2] == "校址"
            school[:address] = line[3..-1]
          # elsif line[0,2] == "地区"
          #   school[:region] = line[3..-1]
          # # deprecated: information we don't need
          # elsif line[0,2] == "网址"
          #   school[:website] = line0.search('a').first.attribute('href').value
          # elsif line[0,2] == "电话"
          #   school[:phone] = line[3..-1]
          end
        end
      end

      return school
    end

  end # School
end # POI

require_relative 'school/elementary'
require_relative 'school/high_school'
require_relative 'school/middle_school'
