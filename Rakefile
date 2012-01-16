require 'rake/testtask'
require 'rake/clean'
require 'redcarpet'

task :default => ['test']
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.ruby_opts << "-rubygems" if RUBY_VERSION < "1.9"
end

CLOBBER << 'doc/html'

MD_SRC    = FileList['doc/*.md', 'readme.md']

DOC_MAP  = MD_SRC.inject({}) { |h,k| h.merge!(k => k.pathmap('doc/html/%n.html')) }
MARKDOWN = Redcarpet::Markdown.new( Redcarpet::Render::XHTML.new( :filter_html => true ),
                                    :fenced_code_blocks => true )

DOC_MAP.each_pair do |md, html|
  file html => md do
    input  = File.read(md)
    output = MARKDOWN.render( input )
    File.open( html, "w+" ) { |f| f.write(output) }
    puts "#{md} -> #{html}"
  end
end
directory 'doc/html'
desc "Build the HTML docs"
task :html => [ 'doc/html', DOC_MAP.values ].flatten
