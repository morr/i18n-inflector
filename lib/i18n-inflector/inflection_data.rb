# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains utility methods,
# that are used by I18n::Inflector and I18n::Backend::Inflector.

# @abstract This namespace is shared with I18n subsystem.
module I18n
  module Inflector

    # This class contains structures for keeping parsed translation data
    # and basic operations for performing on them.
    class InflectionData
      
      # Initializes internal structures.
      def initialize(locale=nil)
        @kinds    = Hash.new(false)
        @tokens   = {}
        @defaults = {}
        @locale   = locale
      end

      # Locale that this database works on.
      attr_reader :locale

      # Adds an alias (overwriting existing alias).
      # 
      # @param [Symbol] name the name of an alias
      # @param [Symbol] target the target token for the given +alias+
      # @return [Boolean] +true+ if everything went ok, +false+ otherwise
      #  (in case of bad or +nil+ names or non-existent targets)
      def add_alias(name, target)
        target  = target.to_s
        name    = name.to_s
        return false if (name.empty? || target.empty?)
        name    = name.to_sym
        target  = target.to_sym
        kind    = get_kind(target)
        return false if kind.nil?
        @tokens[name] = {}
        @tokens[name][:kind]         = kind
        @tokens[name][:target]       = target
        @tokens[name][:description]  = @tokens[target][:description]
        true
      end

      # Adds a token (overwriting existing token).
      # 
      # @param [Symbol] token the name of a token to add
      # @param [Symbol] kind the kind of a token
      # @param [String] description the description of a token
      # @return [void]
      def add_token(token, kind, description)
        token = token.to_sym
        @tokens[token] = {}
        @tokens[token][:kind]         = kind.to_sym
        @tokens[token][:description]  = description.to_s
        @kinds[kind] = true
      end

      # Sets the default token for a kind.
      # 
      # @param [Symbol] kind the kind to which the default
      #   token should be assigned
      # @param [Symbol] target the token to set
      # @return [void]
      def set_default_token(kind, target)
        @defaults[kind.to_sym] = target.to_sym
      end

      # Tests if the token is a true token.
      # 
      # @param [Symbol] token the identifier of a token
      # @return [Boolean] +true+ if the given +token+ is
      #   a token and not an alias, +false+ otherwise 
      def has_true_token?(token)
        @tokens.has_key?(token) && @tokens[token][:target].nil?
      end

      # Tests if a token (or alias) is present.
      # 
      # @param [Symbol] token the identifier of a token
      # @return [Boolean] +true+ if the given +token+ is
      #   (which may be an alias) exists
      def has_token?(token)
        @tokens.has_key?(token)
      end

      # Tests if a kind exists.
      # 
      # @param [Symbol] kind the identifier of a kind
      # @return [Boolean] +true+ if the given +kind+ exists
      def has_kind?(kind)
        @kinds.has_key?(kind)
      end

      # Tests if a kind has a default token assigned.
      # 
      # @param [Symbol] kind the identifier of a kind
      # @return [Boolean] +true+ if there is a default
      #   token of the given kind
      def has_default_token?(kind)
        @defaults.has_key?(kind)
      end

      # Tests if a given alias is really an alias.
      # 
      # @param [Symbol] alias_name the identifier of an alias
      # @return [Boolean] +true+ if the given alias is really an alias,
      #   +false+ otherwise
      def has_alias?(alias_name)
        @tokens.has_key?(alias_name) && !@tokens[alias_name][:target].nil?
      end

      # Reads the all the true tokens (not aliases).
      # 
      # @return [Hash] the true tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_true_tokens(kind)
      #   @return [Hash] the true tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_true_tokens(kind)
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the true tokens of the given kind in a
      #     form of Hash (<tt>token => description</tt>)
      def get_true_tokens(kind=nil)
        tokens = @tokens.reject{|k,v| !v[:target].nil?}
        tokens = tokens.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        tokens.merge(tokens){|k,v| v[:description]}
      end

      # Reads the all the aliases.
      # 
      # @return [Hash] the aliases in a
      #     form of Hash (<tt>alias => target</tt>)
      # @overload get_aliases(kind)
      #   @return [Hash] the aliases in a
      #     form of Hash (<tt>alias => target</tt>)
      # @overload get_aliases(kind)
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the aliases of the given kind in a
      #     form of Hash (<tt>alias => target</tt>)
      def get_aliases(kind=nil)
        aliases = @tokens.reject{|k,v| v[:target].nil?}
        aliases = aliases.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        aliases.merge(aliases){|k,v| v[:target]}
      end

      # Reads the all the tokens in a way that it is possible to
      # distinguish true tokens from aliases.
      # 
      # @note True tokens have descriptions (String) and aliases
      #   have targets (Symbol) assigned.
      # @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description|target</tt>)
      # @overload get_raw_tokens(kind)
      #   @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description|target</tt>)
      # @overload get_raw_tokens(kind)
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the tokens of the given kind in a
      #     form of Hash (<tt>token => description|target</tt>)
      def get_raw_tokens(kind=nil)
        get_true_tokens(kind).merge(get_aliases(kind))
      end

      # Reads the all the tokens (including aliases).
      # 
      # @note Use {get_raw_tokens} if you want to distinguish
      #   true tokens from aliases.
      # @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_raw_tokens(kind)
      #   @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_raw_tokens(kind)
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the tokens of the given kind in a
      #     form of Hash (<tt>token => description</tt>)
      def get_tokens(kind=nil)
        tokens = @tokens
        tokens = tokens.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        tokens.merge(tokens){|k,v| v[:description]}
      end
      
      # Gets a target token for the alias.
      # 
      # @param [Symbol] alias_name the identifier of an alias
      # @return [Symbol,nil] the token that the given alias points to
      #   or +nil+ if it isn't really an alias
      def get_target_for_alias(alias_name)
        @tokens.has_key?(alias_name) ? @tokens[alias_name][:target] : nil
      end
            
      # Gets a kind of the given token or alias.
      # 
      # @param [Symbol] token identifier of a token
      # @return [Symbol,nil] the kind of the given +token+
      #   or +nil+ if the token is unknown
      def get_kind(token)
        @tokens.has_key?(token) ? @tokens[token][:kind] : nil
      end

      # Gets a true token for the given identifier.
      # 
      # @note If the given +token+ is really an alias it will
      #   resolve it and return the real token pointed by that alias
      # @param [Symbol] token the identifier of a token
      # @return [Symbol,nil] the true token for the given +token+
      #   or +nil+ if the token is unknown
      def get_true_token(token)
        return nil unless @tokens.has_key?(token)
        return @tokens[token][:target] || token
      end
      
      # Gets all known kinds.
      # 
      # @return [Array<Symbol>] an array containing all the known kinds
      def get_kinds
        @kinds.keys
      end
      
      # Reads the default token of a kind.
      # 
      # @note It will always return true token (not an alias).
      # @param [Symbol] kind the identifier of a kind
      # @return [Symbol,nil] the default token of the given +kind+
      #   or +nil+ if there is no default token set
      def get_default_token(kind)
        @defaults[kind]
      end

      # Gets a description of a token or alias.
      # 
      # @note If the token is really an alias it will resolve the alias first.
      # @param [Symbol] token the identifier of a token
      # @return [String,nil] the string containing description of the given
      #   token (which may be an alias) or +nil+ if the token is unknown
      def get_description(token)
        @tokens.has_key?(token) ? @tokens[token][:description] : nil
      end
      
      # This method validates default tokens assigned
      # for kinds and replaces targets with true tokens
      # if they are aliases.
      # 
      # @return[nil,Array<Symbol>] +nil+ if everything went fine,
      #   returns two dimensional array containing kind and target
      #   in case of error while geting a token
      def validate_default_tokens
        @defaults.each_pair do |kind, pointer|
          ttok = get_true_token(pointer)
          return [kind, pointer] if ttok.nil?
          set_default_token(kind, ttok) 
        end
        return nil
      end
      
      # Test if the inflection data have no elements.
      # 
      # @return [Boolean] +true+ if the inflection data
      #   have no elements
      def empty?
        @tokens.empty?
      end

    end # InflectionData

  end
end