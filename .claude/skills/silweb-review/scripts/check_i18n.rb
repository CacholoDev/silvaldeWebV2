#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks the i18n of silWeb without booting Rails:
#   1. every literal key used in app/ (t("a.b"), I18n.t("a.b")) exists in
#      every locale under config/locales/;
#   2. es and en have the same keys (nothing translated in only one language).
# Keys built with interpolation (t("x.#{y}")) cannot be checked statically and
# are listed for manual review. Exit code 1 when something is missing.
#
# Usage: ruby check_i18n.rb [project_root]

require "yaml"

root = ARGV[0] || Dir.pwd
locale_files = Dir[File.join(root, "config/locales/**/*.yml")]
abort "No locale files under #{root}/config/locales" if locale_files.empty?

def deep_merge(a, b)
  a.merge(b) { |_k, x, y| x.is_a?(Hash) && y.is_a?(Hash) ? deep_merge(x, y) : y }
end

locales = Hash.new { |h, k| h[k] = {} }
locale_files.each do |file|
  data = YAML.safe_load_file(file, aliases: true) || {}
  data.each { |locale, tree| locales[locale] = deep_merge(locales[locale], tree || {}) }
end

def leaf_keys(tree, prefix = nil)
  tree.flat_map do |k, v|
    key = [ prefix, k ].compact.join(".")
    v.is_a?(Hash) ? leaf_keys(v, key) : [ key ]
  end
end

def lookup(tree, key)
  key.split(".").reduce(tree) { |node, part| node.is_a?(Hash) ? node[part] : nil }
end

# Keys Rails or rails-i18n already provide in English; missing in our files
# is only a warning for them.
RAILS_DEFAULTS = /\A(errors|activerecord\.errors|activemodel\.errors|helpers|number|date|time|datetime|support)\./

used = Hash.new { |h, k| h[k] = [] }
dynamic = []
Dir[File.join(root, "app/**/*.{rb,erb}")].each do |file|
  File.foreach(file).with_index(1) do |line, n|
    line.scan(/(?<![\w.])(?:I18n\.)?t\(\s*["']([^"']+)["']/) do |(key)|
      where = "#{file.delete_prefix("#{root}/")}:#{n}"
      if key.include?('#{') || key.start_with?(".")
        dynamic << "#{where} #{key}"
      else
        used[key] << where
      end
    end
  end
end

failures = 0
warnings = 0
puts "Locales: #{locales.keys.sort.join(", ")} | claves usadas en app/: #{used.size}"

puts "\n== Claves usadas que faltan en algún locale"
used.sort.each do |key, wheres|
  missing = locales.keys.select { |loc| lookup(locales[loc], key).nil? }
  next if missing.empty?

  if key.match?(RAILS_DEFAULTS)
    warnings += 1
    puts "  AVISO  #{key} (falta en #{missing.join(", ")}; puede venir de Rails) — #{wheres.first}"
  else
    failures += 1
    puts "  FALTA  #{key} en #{missing.join(", ")} — #{wheres.first}"
  end
end

puts "\n== Paridad entre locales"
all = locales.transform_values { |tree| leaf_keys(tree).to_set }
all.each do |loc, keys|
  all.each do |other, other_keys|
    next if loc == other

    (keys - other_keys).sort.each do |key|
      failures += 1
      puts "  FALTA  #{key}: está en #{loc} pero no en #{other}"
    end
  end
end

unless dynamic.empty?
  puts "\n== Claves dinámicas (revísalas a mano)"
  dynamic.each { |d| puts "  #{d}" }
end

puts "\n#{failures.zero? ? "OK" : "#{failures} fallo(s)"}, #{warnings} aviso(s)"
exit(failures.zero? ? 0 : 1)
