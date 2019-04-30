Pod::Spec.new do |s|
  s.name = 'ShortcutRecorder'
  s.homepage = 'https://github.com/Kentzo/ShortcutRecorder'
  s.summary = ''
  s.version = '2.17'
  s.source = { :git => 'git://github.com/Kentzo/ShortcutRecorder.git', :branch => 'master' }
  s.author = { 'Ilya Kulakov' => 'kulakov.ilya@gmail.com' }
  s.frameworks = 'Carbon', 'Cocoa'
  s.platform = :osx, "10.6"

  s.subspec 'Core' do |core|
    core.source_files = 'Library/*.{h,m}'
    core.resource_bundles = { "ShortcutRecorder" => ['Resources/*.lproj', 'Resources/*.png'] }
    core.requires_arc = true
    core.prefix_header_file = 'Library/Prefix.pch'
  end

  s.subspec 'PTHotKey' do |hotkey|
    hotkey.source_files = 'PTHotKey/*.{h,m}'
    hotkey.requires_arc = false
    hotkey.dependency 'ShortcutRecorder/Core'
  end
end
