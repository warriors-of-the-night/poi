module POI
  class School
    
    extend POI

    def self.get_max_page_num( type = @type )
      url ="http://xuexiao.eol.cn/iframe/#{type}.php?page=1"
      html = request( url ) 
      html.force_encoding('utf-8')
      page = Nokogiri::HTML( html )
      page.search("center").text[-8..-1].match('\d{2,}').to_s.to_i
    end

    def self.urls_in_page( page_i, type = @type )
      url ="http://xuexiao.eol.cn/iframe/#{type}.php?page=#{page_i}"
      html = request( url ) 
      page = Nokogiri::HTML( html )

      urls = []
      ( page.search('h1') + page.search('h5') ).each do |heading|
        # why nokogiti will erase ''index.shtml here
        urls << heading.search('a').attribute('href').value + 'index.shtml'
      end

      return urls
    end

    def self.get_info( url )
      html = request( url )
      page = Nokogiri::HTML( html )

      school = {}
      school[:name] = page.search('title').text.split('-')[0]

      table = page.search("table[@class='line_22']")
      table.search('td').each do |line0|
        line = line0.text
        if line[0,2] == "校址"
          school[:address] = line[3..-1]
        elsif line[0,2] == "地区"
          school[:region] = line[3..-1]
        # # deprecated: information we don't need
        # elsif line[0,2] == "网址"
        #   school[:website] = line0.search('a').first.attribute('href').value
        # elsif line[0,2] == "电话"
        #   school[:phone] = line[3..-1]
        end
      end

      return school
    end

  end # School
end # POI

# Can I put require to the top of the file?
require 'school/elementary'
require 'school/high_school'
require 'school/middle_school'
