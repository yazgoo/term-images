require "version"
require 'os'
require 'mkmf'

module TermImages

  module MakeMakefile::Logging
    @logfile = File::NULL
    @quiet = true
  end
  class Error < StandardError; end
  class Image
    def initialize path
      @path = path
    end
    class CommandLineImageDisplayer
      def initialize args
        @args = args
      end
      def run path
        if find_executable(@args.first)
          co = (@args << path)
          system(*co)
        end
      end
    end
    class Cursor
      class << self
        def pos
          res = ''
          $stdin.raw do |stdin|
            $stdout << "\e[6n"
            $stdout.flush
            while (c = stdin.getc) != 'R'
              res << c if c
            end
          end
          m = res.match /(?<row>\d+);(?<column>\d+)/
          { row: Integer(m[:row]), column: Integer(m[:column]) }
        end
      end
    end
    class W3MImageDisplayer
      def initialize
        @w3mimgdisplay = "/usr/lib/w3m/w3mimgdisplay"
      end
      def supported?
        File.exists? @w3mimgdisplay
      end
      def run path
        fonth=12
        fontw=8
        columns=`tput cols`.chomp.to_i
        lines=`tput lines`.chomp.to_i
        arr = `echo -e "5;#{path}" | #{@w3mimgdisplay}`.chomp.split(" ")
        width = arr[0].to_i
        height = arr[1].to_i
        max_width=fontw * columns
        max_height=fonth * (lines - 2) # substract one line for prompt
        if width > max_width
          height=(height * max_width / width)
          width=max_width
        end
        if height > max_height
          width=(width * max_height / height)
          height=max_height
        end
        c = Cursor.pos
        (height / fonth).to_i.times do
          puts
        end
        w3m_command="0;1;#{c[:column] * fontw};#{c[:row] * fonth};#{width};#{height};;;;;#{path}\\n4;\\n3;"
        `tput cup #{height/fonth} 0`
        `echo -e "#{w3m_command}"|#{@w3mimgdisplay}`
      end
    end
    def pstree pid = Process.pid
      processes = []
      while pid != 0
        `/bin/ps #{::OS.mac? ? "-p" : "axww -q"} #{pid} -o ppid,command`.each_line do |line|
          next if line !~ /^\s*\d+/
          line.strip!
          result = line.split(/\s+/, 2)
          processes << result[1].split(" ").first.split("/").last
          pid = result[0].to_i
        end
      end
      processes
    end
    def puts
      commands = {
        "kitty" => CommandLineImageDisplayer.new([(::OS.mac? ? "/Applications/kitty.app/Contents/MacOS/" : "") + "kitty", "+kitten", "icat"]),
        "terminology" => CommandLineImageDisplayer.new(%w(tycat)),
        "mlterm" => CommandLineImageDisplayer.new(%w(img2sixel)),
        "iTerm" => CommandLineImageDisplayer.new(%w(imgcat))
      }
      ptree = pstree
      terminals = commands.keys.map { |terminal| ptree.include?(terminal) ? terminal : nil }.select { |x| !x.nil? }
      if terminals.size > 0
        command = commands[terminals.first]
      else
        w3mImageDisplayer = W3MImageDisplayer.new
        if w3mImageDisplayer.supported?
          command = w3mImageDisplayer
        else
          command = CommandLineImageDisplayer.new %w(icat)
        end
      end
      command.run @path
    end
  end
end
