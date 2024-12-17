Faraday.default_connection = Faraday.new do |conn|
  conn.use Faraday::FollowRedirects::Middleware
  conn.adapter Faraday.default_adapter
end
