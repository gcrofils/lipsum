#
# Lorem Ipsum Ruby Generator Library
#
# Author::    Gilles Crofils  (mailto:gilles@secondbureau.com)
# Copyright:: Copyright (c) 2010 Second Bureau
# License::   Distributes under the same terms as Ruby
# Home::      http://github.com/gcrofils/lipsum
#


require 'rubygems'
require 'active_record'

# Usage: Lipsum.generate(:words => 50)
module Lipsum
    
    class UnsupportedType < StandardError #:nodoc:
    end
    class MustBePositive < StandardError #:nodoc:
    end
    class NilNotAllowed < StandardError #:nodoc:
    end
       
    class << self
      def generate(opts = {})
        l = Lipsum::Base.new.generate(opts)
      end
    end
  
    class Base
      
      attr_accessor :options
      attr_accessor :text
      
      # words extracts from http://lipsum.com
      WORDS   = %w[ a ac accums accumsan ad adipiscing aenean al aliquam aliquet amet ante aptent arcu at auctor augue bibendum blandit class commodo condimentum congue consectetur consequat conubia convalli convallis cras cubilia cum curabitur curae; cursus dapibus diam dictum dictumst digniss dignissim dis dolor donec dui duis egestas eget el eleifend elementum elit enim erat eros est et etiam eu euismod facilisi facilisis fames fau faucib faucibu faucibus felis fermentum feugiat fringilla fusce gravida habitant habitasse hac hendrerit himenaeos iaculis id imperdiet in inceptos integer interdum ipsum jus justo lac lacinia lacus laoreet lectus leo li libero ligula litora lobortis lorem luctus ma maecenas magna magnis malesuada massa mattis mauris metus mi molestie mollis montes morbi mus nam nascetur natoque nec neque netus nibh nisi nisl non nostra nulla nullam nunc odio orci ornare p parturient pellentesque penatibus per pharetra phasellus placerat platea porta porttitor posuere potenti praesent pretium primis proin pulvinar purus quam quis quisque rhoncus ridiculus risus rutrum sagittis sapien scelerisque se sed sem semper senectus sit sociis sociosqu sodales sollicitudin suscipit suspendisse taciti tellus tempor tempus tincid tincidunt tor torquent tortor tristique turpis ul ull ullamcorper ultri ultrices ultricies urna ut varius vehicula vel velit venenatis vestibulum vitae vivamus viverra volutpat vulputate ]
      # first phrase
      LIPSUM  = %w[ lorem ipsum dolor sit amet ]
      # first phrase (part 2)
      CONSECTETUR = %w[ consectetur adipiscing elit ]
      # allowed units of measures
      TYPES   = [:words, :paragraphs, :characters]
      
      MIN_NUMBER_OF_PARAGRAPHS = 1
      MIN_NUMBER_OF_WORDS = 5
      MIN_NUMBER_OF_CHARACTERS = 27
      MIN_NUMBER_OF_WORDS_BY_PARAGRAPH = 200
      
      def initialize(opts = {})
        define_options(opts)
      end
      
      def generate(opts = nil)
        define_options(opts) unless opts.nil?
        @stats = nil
        @text = run
      end
    
      def stats
        @stats ||= compute_stats
      end
 
private

        def define_options(opts)
          @options ||= {
            :start_with_lipsum => true,
            :paragraphs => MIN_NUMBER_OF_PARAGRAPHS,
            :words => MIN_NUMBER_OF_WORDS,
            :characters => MIN_NUMBER_OF_CHARACTERS,
            :type => :words,
            :force => false
          }
          @options = @options.merge(opts)
          check_options
          define_type
        end
        
        def check_options
          nil_not_allowed
          must_be_positive
        end
        
        def nil_not_allowed
          @options.each{|k,v| raise NilNotAllowed if v.nil?}
        end
        
        def must_be_positive
          TYPES.each{|t| raise MustBePositive if @options[t]< 1}
        end

        # try to guess what kind of generator you want
        # use :force => true to force :type => whatever
        def define_type
          raise UnsupportedType unless TYPES.include?(@options[:type])
          unless @options[:force]
            TYPES.each{|t| @options[:type] = t unless @options[t].eql?(self.class.const_get("MIN_NUMBER_OF_#{t.to_s.upcase}")) }
          end
        end
        
        def run
          self.send(@options[:type])
        end
        
        def paragraphs
          text = ''
          buffer = ''
          nbparagraphs = 0
          nbwords = 0
          totalwords = calculate_total_words
          while nbparagraphs < options[:paragraphs]
            w = nbparagraphs.eql?(options[:paragraphs] -1) ? totalwords - nbwords : [MIN_NUMBER_OF_WORDS_BY_PARAGRAPH, (totalwords - nbwords) / @options[:paragraphs]].max + rand(50)
            nbwords += w
            #log "#{w} #{totalwords - nbwords}"
            start_with_lipsum = (@options[:start_with_lipsum] and (nbparagraphs.eql?(0)))
            text += "#{Lipsum::Base.new(@options).generate(:type => :words, :force => true, :words => w, :start_with_lipsum => start_with_lipsum)}\n" 
            nbparagraphs += 1
          end
          text.strip
        end
        
        def calculate_total_words
          if options[:paragraphs].eql?(1)
            options[:words]
          else
            [MIN_NUMBER_OF_WORDS_BY_PARAGRAPH * options[:paragraphs],  options[:words]].max
          end
        end
      
        def characters
          text = ''
          buffer = ''
          if @options[:start_with_lipsum]
          buffer = LIPSUM.dup.join(' ') 
          buffer = "#{buffer}, #{CONSECTETUR.dup.join(' ')}" if @options[:characters] >= LIPSUM.dup.join(' ').length + CONSECTETUR.dup.join(' ').length
          end
          while (text.length + buffer.length) < (@options[:characters])
            buffer = "#{buffer}#{buffer.length>0 ? ' ' :''}#{word(@options[:characters] - text.length - buffer.length - (buffer.length>0 ? 2 :1))}"
            unless (buffer.length + text.length) > (@options[:characters] - 10)
              if rand(100) < 15
                text += "#{buffer.capitalize}. "
                buffer = ''
             elsif rand(100) < 8
                buffer += ','
              end
            end
            break buffer if  @options[:characters].eql?(text.length + buffer.length + 1)
          end
          text += "#{buffer.capitalize}."
          text
        end
        
        def words
          text = ''
          buffer = ''
          nbwords = 0
          if options[:start_with_lipsum]
            buffer = LIPSUM.dup.join(' ')
            nbwords = LIPSUM.size
          
          if options[:words] >= LIPSUM.size + CONSECTETUR.size
            buffer = "#{buffer}, #{CONSECTETUR.dup.join(' ')}"
            nbwords += CONSECTETUR.size
          end
          end
          while nbwords < @options[:words]
            buffer = "#{buffer} #{word}"
            nbwords += 1
            unless nbwords.eql?(@options[:words])
              if rand(100) < 15
                text += "#{buffer.strip.capitalize}. "
                buffer = ''
              elsif rand(100) < 8
                buffer += ','
              end
            end
          end
          text += "#{buffer.strip.capitalize}."
          text
        end
        
        def min_word_size
          @min_word_size ||= WORDS.map{|w| w.length}.min
        end

        def max_word_size
          @max_word_size ||= WORDS.map{|w| w.length}.max
        end
        
        # return a word of requested length
        def word(length=0)
          words = (length.eql?(0) or length > max_word_size)? WORDS : WORDS.select{|w| w.length.eql?(length)}
          words.shuffle.first
      end
      
      def compute_stats
          @stats = {}
          @stats[:paragraphs] = (text || '').split("\n").size
          @stats[:words]      = (text || '').gsub('.', '').gsub(',', '').gsub("\n",' ').split(' ').size
          @stats[:characters] = (text || '').length
          @stats
      end
        
      
    end

end
