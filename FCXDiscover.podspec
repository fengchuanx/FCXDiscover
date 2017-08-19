
Pod::Spec.new do |s|

  s.name         = "FCXDiscover"
  s.version      = "0.0.1"
  s.summary      = "FCX’s FCXDiscover."
  s.description  = <<-DESC
                    FCXDiscover of FCX
                   DESC

  s.homepage     = "https://github.com/fengchuanx/FCXDiscover"
  s.license      = "MIT"
  s.author             = { "fengchuanx" => "fengchuanxiangapp@126.com" }

  s.source       = { :git => "https://github.com/fengchuanx/FCXDiscover.git", :tag => "0.0.1" }
  s.platform     = :ios, "8.0"

  s.source_files  = "FCXDiscover/"

  s.dependency "SDWebImage", "~> 3.7.5"

end
