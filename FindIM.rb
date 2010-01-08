# FindIM - "Find IMproved"
# 
# simple file indexer using ferret           
# author: thiago.moretto
require 'ferret'

module FindIM
	Messages = { 
		:path_must_be_not_null => "path must be null", 
		:path_must_be_a_diretory => "path must be a directory"
	}
		
	# This class is used to configure
	# and to build a new index based 
	# on a pattern of file names and
	# the directory.
	class Indexer
		def initialize (params)
			@params = params 
			@index = Ferret::Index::Index.new :path => '/tmp/findIM',
						:analyzer => Ferret::Analysis::WhiteSpaceAnalyzer.new
		end
		
		# Create a index
		def create_index
			raise Messages[:path_must_be_not_null] unless @params[:path]
			raise Messages[:path_must_be_a_diretory] unless File.directory? @params[:path]
			index_dir @params[:path]
		end
		
		def index
			@index
		end
		
		# Return true if file is indexable
		# based on pattern, file length, and permissions.
		private
		def index_dir dir
			dir = Dir.new dir
			dir.each{ |f| 
				full_path = "#{dir.path}/#{f}"
				index_file full_path if File.file? full_path and indexable? full_path
				index_dir full_path if File.directory? full_path and f != '.' and f != '..'
			}			
		end
		
		def indexable? candidate
			puts "testing if #{candidate} is indexable."
			/\.java/ =~ File.basename(candidate) and File.readable? candidate # TODO
		end
		
		def index_file file
			puts "indexing file #{file}..."
			@index << { :filepath => file,
				:filename => File.basename(file), 
				:content => read_file_to_string(file) }
		end
		
		def read_file_to_string file
			content = ''
			File.open(file, 'r') { |f|
				content << f.read
			}
			content
		end
	end
	
	# searcher
	class Searcher
		def initialize index
			@index = index
		end
		
		def search query
			@index.search_each(query) do |id, score|
				puts "Document #{@index[id][:filename]} found with score #{score}"
			end
		end				
	end
	                                      
	# highlighting
	class HighlightSearch 
		def initialize index
			@index = index
		end
		
		def search query
			@index.search_each(query) do |id, score|
				puts "Document #{@index[id][:filename]} found with a score of #{score}"
				highlights = @index.highlight(query, 0,
					:field => :content,	:pre_tag => "\033[36m",	:post_tag => "\033[m")
				puts highlights				
			end
		end				
	end
end

indexer = FindIM::Indexer.new :path => '/Users/thiago/git', :pattern =>'*.rb'
indexer.create_index
                     
# testing
fuzzyQuery = Ferret::Search::FuzzyQuery.new(
		:content, 'points', # my content to search
		:min_similarity => 0.5,
		:prefix_length => 1)

searcher = FindIM::HighlightSearch.new indexer.index
searcher.search fuzzyQuery

