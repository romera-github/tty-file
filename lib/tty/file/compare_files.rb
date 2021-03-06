# frozen_string_literal: true

require_relative "differ"

module TTY
  module File
    class CompareFiles
      extend Forwardable

      def initialize(format: :unified, header: true, context_lines: 5,
                     verbose: true, color: :green, noop: false, diff_colors: nil)
        @format = format
        @header = header
        @context_lines = context_lines
        @verbose = verbose
        @color = color
        @noop = noop
        @diff_colors = diff_colors
      end

      # Compare files
      #
      # @api public
      def call(file_a, file_b, file_a_path, file_b_path)
        differ = Differ.new(format: @format, context_lines: @context_lines)
        block_size = file_a.lstat.blksize
        file_a_chunk = file_a.read(block_size)
        file_b_chunk = file_b.read(block_size)
        hunks = differ.(file_a_chunk, file_b_chunk)

        return "" if file_a_chunk.empty? && file_b_chunk.empty?
        return "No differences found\n" if hunks.empty?

        output = []

        if %i[unified context old].include?(@format) && @header
          output << "#{differ.delete_char * 3} #{file_a_path}\n"
          output << "#{differ.add_char * 3} #{file_b_path}"
        end

        output << "\n" unless hunks =~ /\A\n+@@/
        output << hunks
        while !file_a.eof? && !file_b.eof?
          output << differ.(file_a.read(block_size), file_b.read(block_size))
        end
        color_diff_lines(output.join)
      end

      private

      # @api private
      def color_diff_lines(hunks)
        return hunks unless @color && @format == :unified

        newline = "\n"
        hunks.lines.map do |line|
          if matched = line.to_s.match(/^(\+[^+]*?)\n/)
            @diff_colors[:green].(matched[1]) + newline
          elsif matched = line.to_s.match(/^(\-[^-].*?)\n/)
            @diff_colors[:red].(matched[1]) + newline
          elsif matched = line.to_s.match(/^(@@.+?@@)\n/)
            @diff_colors[:cyan].(matched[1]) + newline
          else
            line
          end
        end.join
      end
    end # CompareFiles
  end # File
end # TTY
