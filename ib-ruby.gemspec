# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.required_ruby_version = '~> 2.4'
  gem.name = "ib-ruby"
  gem.version = File.open('VERSION').read.strip
  gem.summary = "Ruby Implementation of the Interactive Brokers TWS API"
  gem.description = "Ruby Implementation of the Interactive Brokers TWS API"
  gem.authors = ["Paul Legato", "arvicco",'Hartmut Bischoff']
  gem.email = ["pjlegato@gmail.com", "arvicco@gmail.com","topofocus@gmail.com"]
  gem.homepage = "https://github.com/topofocus/ib-ruby"
  gem.platform = Gem::Platform::RUBY
  gem.date = Time.now.strftime "%Y-%m-%d"
  gem.license = 'MIT'

  # Files setup
  versioned = `git ls-files -z`.split("\0")
  gem.files = Dir['{app,config,db,bin,lib,man,spec,features,tasks}/**/*',
                  'Rakefile', 'README*', 'LICENSE*',
                  'VERSION*', 'HISTORY*', '.gitignore'] & versioned
  gem.executables = (Dir['bin/**/*'] & versioned).map { |file| File.basename(file) }
  gem.test_files = Dir['spec/**/*'] & versioned
  gem.require_paths = ['lib']

  # Dependencies
  gem.add_dependency 'bundler', '~> 1.13'
  gem.add_dependency 'activesupport', '~> 5.0'
  gem.add_dependency 'xml-simple', '~> 1.1'
  gem.add_dependency 'activemodel-serializers-xml', '~>1.0'
  gem.add_dependency 'rspec', '~> 3.5'

end
