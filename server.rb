require 'socket'

class Response
  HTTP_VERSION = 1.1
  attr_accessor :status, :body, :header

  def initialize(opts = {})
    @status ||= opts[:status] || 200
    @body   ||= opts[:body]   || ''

    @header = default_header
    opts[:header].each { |k, v| @header[k] = v } if opts[:header] === Hash

    yield self if block_given?
  end

  def default_header
    {
      'Content-Type': 'text/html',
      'Content-Length': @body.length.to_s
    }
  end

  def normalized_header_param
    @header.map do |k, v|
      "#{k}: #{v}"
    end.join('\n')
  end

  def message
    case @status
    when 200
      'OK'
    when 404
      'Not Found'
    else
      ''
    end
  end

  def render
    <<-EOS
HTTP/#{HTTP_VERSION} #{@status} #{message}
#{normalized_header_param}

#{body}
EOS
  end
end

class Request
  attr_accessor :method, :path

  def initialize(request_str)
    # @parser = RequestParser.new
    # param = @parser.parse(request_str) || {}

    self.parse(request_str)
  end

  def parse(request_str)
    request_args = request_str.split(/\s/).reject(&:empty?)

    @method = request_args[0]
    @path   = request_args[1]
  end
end

# class RequestParser; end

# class Application; end

# class Router; end

server = TCPServer.open(8080)

while true
  Thread.start(server.accept) do |client|
    request = Request.new(client.gets)
    response = Response.new

    response.body = "METHOD: #{request.method}\nPATH: #{request.path}"

    client.puts response.render
    client.close
  end
end
