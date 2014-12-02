require "nokogiri"
require 'open-uri'
require "socket"

require 'poi/elementary'
require 'poi/middle_school'
require 'poi/high_school'

module POI
  def request( url )
    """
    Sent HTTP request to baidu and grab the respond html.
    """
    # force encoding
    url = URI::encode(url)

    # here we can extract another method: separate URL
    host = URI(url).host
    uri = url[ 7 + host.length .. -1 ]

    http_request = "GET #{uri} HTTP/1.1\r\n"+
    "Content-Type: text/html; charset=utf-8\r\n"+
    "Host:#{host}\r\n"+
    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"+
    "Connection:keep-alive\r\n"+
    "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:33.0) Gecko/20100101 Firefox/33.0\r\n\r\n"
    socket = TCPSocket.open( host, 80)

    socket.puts( http_request)

    html = ""
    while line = socket.gets
      html += line
      # automatically end
      break if html.include?('</HTML>') || html.include?('</html>')
    end
    socket.close

    return html
  end
end