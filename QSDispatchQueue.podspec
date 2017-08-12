Pod::Spec.new do |s|
s.name         = "QSDispatchQueue"
s.version      = "1.0.0"
s.summary      = "A way to control maxConcurrentCount of GCD concurrent queue"
s.homepage     = "https://github.com/buaa0300/QSDispatchQueue"
s.license      = "MIT"
s.authors      = {"南华coder" => "buaa0300@163.com"}
s.platform     = :ios, "7.0"
s.source       = {:git => "https://github.com/buaa0300/QSDispatchQueue.git", :tag => s.version}
s.requires_arc = true
s.source_files = "QSDispatchQueue/*.{h,m}"
end
