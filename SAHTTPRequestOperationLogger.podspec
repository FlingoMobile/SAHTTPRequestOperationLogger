Pod::Spec.new do |s|
  s.name     = 'SAHTTPRequestOperationLogger'
  s.version  = '1.0.0'
  s.license  = 'MIT'
  s.summary  = 'SANetworking Extension for HTTP Request Logging'
  s.homepage = 'https://github.com/FlingoMobile/SAHTTPRequestOperationLogger'
  s.authors  = { 'Mattt Thompson' => 'm@mattt.me' }
  s.source   = { :git => 'https://github.com/FlingoMobile/SAHTTPRequestOperationLogger.git', :tag => '1.0.0' }
  s.source_files = 'SAHTTPRequestOperationLogger.{h,m}'
  s.requires_arc = true

  s.dependency 'SANetworking', '~> 1.0'
end
