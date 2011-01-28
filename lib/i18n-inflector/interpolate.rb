# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains I18n::Inflector::Interpolate module,
# which is included in API.

module I18n
  module Inflector
    
    # This module contains methods for interpolating
    # inflection patterns.
    module Interpolate

      # Interpolates inflection values in the given +string+
      # using kinds given in +options+ and a matching tokens.
      # 
      # @param [String] string the translation string
      #  containing patterns to interpolate
      # @param [String,Symbol] locale the locale identifier 
      # @param [Hash] options the options
      # @option options [Boolean] :inflector_excluded_defaults (false) local switch
      #   that overrides global setting (see: {I18n::Inflector::InflectionOptions#excluded_defaults})
      # @option options [Boolean] :inflector_unknown_defaults (true) local switch
      #   that overrides global setting (see: {I18n::Inflector::InflectionOptions#unknown_defaults})
      # @option options [Boolean] :inflector_raises (false) local switch
      #   that overrides global setting (see: {I18n::Inflector::InflectionOptions#raises})
      # @option options [Boolean] :inflector_aliased_patterns (false) local switch
      #   that overrides global setting (see: {I18n::Inflector::InflectionOptions#aliased_patterns})
      # @return [String] the string with interpolated patterns
      def interpolate(string, locale, options = {})
        used_kinds        = options.except(*INFLECTOR_RESERVED_KEYS)
        sw, op            = @options, options
        raises            = (s=op.delete :inflector_raises).nil?            ? sw.raises            : s
        aliased_patterns  = (s=op.delete :inflector_aliased_patterns).nil?  ? sw.aliased_patterns  : s
        unknown_defaults  = (s=op.delete :inflector_unknown_defaults).nil?  ? sw.unknown_defaults  : s
        excluded_defaults = (s=op.delete :inflector_excluded_defaults).nil? ? sw.excluded_defaults : s

        idb               = @idb[locale]
        idb_strict        = @idb_strict[locale]

        string.gsub(PATTERN) do
          pattern_fix     = $1
          strict_kind     = $2
          pattern_content = $3
          ext_pattern     = $&
          ext_value       = nil
          ext_freetext    = ''
          found           = nil
          parsed_default_v= nil

          # leave escaped pattern as-is
          unless pattern_fix.empty?
            ext_pattern = ext_pattern[1..-1]
            next ext_pattern if ESCAPES[pattern_fix]
          end

          # set parsed kind if strict kind is given (named pattern is parsed) 
          if strict_kind.empty?
            parsed_symbol = nil
            strict_kind   = nil
            parsed_kind   = nil
            default_token = nil
            subdb         = idb
          else
            parsed_symbol = (NAMED_MARKER + strict_kind).to_sym
            strict_kind   = strict_kind.to_sym
            parsed_kind   = strict_kind
            subdb         = idb_strict
            default_token = subdb.get_default_token(parsed_kind)
          end

          # process pattern content's
          pattern_content.scan(TOKENS) do
            ext_token     = $1.to_s
            ext_value     = $2.to_s
            ext_freetext  = $3.to_s
            tokens        = Hash.new(false)
            negatives     = Hash.new(false)
            kind          = nil
            option        = nil

            # token not found?
            if ext_token.empty?
              # free text not found too? that should never happend.
              if ext_freetext.empty?
                raise I18n::InvalidInflectionToken.new(ext_pattern, ext_token) if raises
              end
              next
            end

            # split tokens if comma is present and put into fast list
            ext_token.split(OPERATOR_MULTI).each do |t|
              # token name corrupted
              if t.empty?
                raise I18n::InvalidInflectionToken.new(ext_pattern, t) if raises
                next
              end

              # mark negative-matching tokens and put them to negatives fast list
              if t[0..0] == OPERATOR_NOT
                t = t[1..-1]
                if t.empty?
                  raise I18n::InvalidInflectionToken.new(ext_pattern, t) if raises
                  next
                end
                t = t.to_sym
                t = subdb.get_true_token(t, strict_kind) if aliased_patterns
                negatives[t] = true
              end

              t = t.to_sym
              t = subdb.get_true_token(t, strict_kind) if aliased_patterns

              # get kind for that token
              kind  = subdb.get_kind(t, strict_kind)
              if kind.nil?
                raise I18n::InvalidInflectionToken.new(ext_pattern, t) if raises
                next
              end

              # set processed kind after matching first token in a pattern
              if parsed_kind.nil?
                parsed_kind   = kind
                parsed_symbol = kind.to_sym
                default_token = subdb.get_default_token(parsed_kind)
              elsif parsed_kind != kind
                # tokens of different kinds in one regular (not named) pattern are prohibited
                if raises
                  raise I18n::MisplacedInflectionToken.new(ext_pattern, t, parsed_symbol)
                end
                next
              end

              # use that token
              tokens[t] = true unless negatives[t]
            end

            # self-explanatory
            if (tokens.empty? && negatives.empty?)
              raise I18n::InvalidInflectionToken.new(ext_pattern, ext_token) if raises
            end

            # try @-style option for strict kind, fallback to regular if not found
            # and memorize option name for error reporting
            oname = !strict_kind.nil? && used_kinds.has_key?(parsed_symbol) ?
                    parsed_symbol : (used_kinds.has_key?(kind) ? kind : nil)

            # Get option if possible and memorize for error reporting;
            # fallback to default token if option still not found
            if oname.nil?
              option      = default_token
              orig_option = nil
            else
              option      = used_kinds[oname]
              orig_option = option
            end

            if (option.nil? || option.to_s.empty?)
              # if option is given but is unknown, empty or nil
              # then use default option for a kind if unknown_defaults is switched on
              option = unknown_defaults ? default_token : nil
            else
              # validate option and if it's unknown try in aliases
              option = subdb.get_true_token(option.to_sym, strict_kind)

              # if still nothing then fall back to default value
              # for a kind if unknown_defaults switch is on
              if option.nil?
                option = unknown_defaults ? default_token : nil
              end
            end

            # if the option is still unknown or bad
            # raise an exception
            if option.nil?
              if raises
                if oname.nil?
                  ex          = InflectionOptionNotFound
                  oname       = parsed_symbol
                  orig_option = nil
                else
                  ex          = InflectionOptionIncorrect
                end
                raise ex.new(ext_pattern, oname, ext_token, orig_option)
              end
              next
            end

            # memorize default value for further processing
            # outside this block if excluded_defaults switch is on
            parsed_default_v = ext_value if (excluded_defaults && !default_token.nil?)

            # throw the value if the given option matches one of the tokens from group
            # or negatively matches one of the negated tokens
            case negatives.count
            when 0 then next unless tokens[option]
            when 1 then next if  negatives[option]
            end

            # skip further evaluation of the pattern
            # since the right token has been found
            found = option
            break

          end # single token (or a group) processing

          # return value of a token that matches option's value
          # given for a kind or try to return a free text
          # if it's present
          if found.nil?
            # if there is excluded_defaults switch turned on
            # and a correct token was found in an inflection option but
            # has not been found in a pattern then interpolate
            # the pattern with a value picked for the default
            # token for that kind if a default token was present
            # in a pattern
            ext_value = (excluded_defaults && !parsed_kind.nil? &&
                         subdb.has_token?(used_kinds[parsed_kind], parsed_kind)) ?
                         parsed_default_v : nil
          elsif ext_value == LOUD_MARKER  # interpolate loud tokens
            ext_value = subdb.get_description(found, parsed_kind)
          elsif ext_value[0..0] == ESCAPE
            ext_value.sub!(ESCAPE_R, '\1')
          end

          pattern_fix + (ext_value || ext_freetext)

        end # single pattern processing

      end # def interpolate
      
    end # module Interpolate
  end # module Inflector
end # module I18n

