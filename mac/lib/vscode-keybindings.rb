#!/usr/bin/ruby
# Preserve personal JSONC content while maintaining one setup-owned binding block.
require 'json'
require 'fileutils'

module VSCodeKeybindings
  FIRST = '// >>> mac-setup enter-open >>>'.freeze
  LAST = '// <<< mac-setup enter-open <<<'.freeze

  def self.mask_comments(text)
    # Match strings first so comment-like text inside strings is left intact.
    text.gsub(/"(?:\\.|[^"\\])*"|\/\/[^\r\n]*|\/\*.*?\*\//m) do |token|
      token.start_with?('"') ? token : token.gsub(/[^\r\n]/, ' ')
    end
  end

  def self.jsonc(text)
    # VS Code allows trailing commas. Again, do not alter quoted strings.
    mask_comments(text).gsub(/"(?:\\.|[^"\\])*"|,(\s*[\]}])/m) { |token| $1 || token }
  end

  def self.merge(original, bindings)
    raise 'Expected keybinding objects' unless bindings.is_a?(Array) && bindings.all? { |entry| entry.is_a?(Hash) }
    pattern = /^[ \t]*#{Regexp.escape(FIRST)}\r?\n.*?^[ \t]*#{Regexp.escape(LAST)}[ \t]*\r?\n?/m
    count = original.scan(FIRST).size
    if count != original.scan(LAST).size || count > 1 || (count == 1 && !original.match?(pattern))
      raise 'Malformed managed VS Code keybinding block'
    end
    # Validate before editing so malformed personal settings are never overwritten.
    parsed = JSON.parse(jsonc(original))
    raise 'Expected a keybindings array' unless parsed.is_a?(Array) && parsed.all? { |entry| entry.is_a?(Hash) }
    text = original.sub(pattern, '')
    clean = jsonc(text)
    entries = JSON.parse(clean)
    # Mask comments without removing trailing commas to retain source offsets.
    masked = mask_comments(text)
    closing = masked.rindex(']')
    prefix = text[0...closing]
    comma = entries.empty? || masked[0...closing].rstrip.end_with?(',') ? '' : ','
    block = "  #{FIRST}\n" + bindings.map { |entry| JSON.pretty_generate(entry).lines.map { |line| "  #{line}" }.join.rstrip + ",\n" }.join + "  #{LAST}\n"
    result = prefix + comma + (prefix.end_with?("\n") && comma.empty? ? '' : "\n") + block + text[closing..-1]
    JSON.parse(jsonc(result))
    result
  end
end

if $PROGRAM_NAME == __FILE__
  path, source = ARGV
  abort 'Expected destination and binding asset paths' unless source
  original = File.file?(path) ? File.read(path) : "[\n]\n"
  result = VSCodeKeybindings.merge(original, JSON.parse(File.read(source)))
  unless original == result && File.file?(path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, result)
  end
end
