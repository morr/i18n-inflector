# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains class that is used to keep
# inflection data.

# @abstract This namespace is shared with I18n subsystem.
module I18n
  module Inflector

    # This class contains structures for keeping parsed translation data
    # and basic operations for performing on them.
    class InflectionData < InflectionData_Strict

      # Initializes internal structures.
      # 
      # @param [Symbol,nil] locale the locale identifier for the object to be labeled with
      def initialize(locale=nil)
        @kinds          = Hash.new(false)
        @tokens         = Hash.new(DUMMY_TOKEN)
        @defaults       = Hash.new
        @lazy_tokens    = LazyHashEnumerator.new(@tokens)
        @locale         = locale
      end

      # Adds an alias (overwriting an existing alias).
      # 
      # @return [Boolean] +true+ if everything went ok, +false+ otherwise
      #     (in case of bad or +nil+ names or non-existent targets)
      # @overload add_alias(name, target)
      #   Adds an alias (overwriting an existing alias).
      #   @param [Symbol] name the name of an alias
      #   @param [Symbol] target the target token for the given +alias+
      #   @return [Boolean] +true+ if everything went ok, +false+ otherwise
      #     (in case of bad or +nil+ names or non-existent targets)
      # @overload add_alias(name, target, kind)
      #   Adds an alias (overwriting an existing alias) if the given
      #   +kind+ matches the kind of the given target.
      #   @param [Symbol] name the name of an alias
      #   @param [Symbol] target the target token for the given +alias+
      #   @param [Symbol] kind the optional kind of a taget
      #   @return [Boolean] +true+ if everything went ok, +false+ otherwise
      #     (in case of bad or +nil+ names or non-existent targets)
      def add_alias(name, target, kind=nil)
        target  = target.to_s
        name    = name.to_s
        return false if (name.empty? || target.empty?)
        kind    = nil if kind.to_s.empty? unless kind.nil?
        name    = name.to_sym
        target  = target.to_sym
        t_kind  = get_kind(target)
        return false if (t_kind.nil? || (!kind.nil? && t_kind != kind))
        @tokens[name] = {}
        @tokens[name][:kind]        = kind
        @tokens[name][:target]      = target
        @tokens[name][:description] = @tokens[target][:description]
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

      # Tests if the token is a true token.
      # 
      # @overload has_true_token?(token)
      #   Tests if the token is a true token.
      #   @param [Symbol] token the identifier of a token
      #   @return [Boolean] +true+ if the given +token+ is
      #     a token and not an alias, +false+ otherwise 
      # @overload has_true_token?(token, kind)
      #   Tests if the token is a true token.
      #   The kind will work as the expectation filter.
      #   @param [Symbol] token the identifier of a token
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Boolean] +true+ if the given +token+ is
      #     a token and not an alias, and is a kind of
      #     the given kind, +false+ otherwise 
      def has_true_token?(token, kind=nil)
        o = @tokens[token]
        k = o[:kind]
        return false if (k.nil? || !o[:target].nil?)
        kind.nil? ? true : k == kind
      end

      # Tests if a token (or alias) is present.
      # 
      # @overload has_token(token)
      #   Tests if a token (or alias) is present.
      #   @param [Symbol] token the identifier of a token
      #   @return [Boolean] +true+ if the given +token+ 
      #     (which may be an alias) exists
      # @overload has_token(token, kind)
      #   Tests if a token (or alias) is present.
      #   The kind will work as the expectation filter.
      #   @param [Symbol] token the identifier of a token
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Boolean] +true+ if the given +token+ 
      #     (which may be an alias) exists and if kind of
      #     the given kind
      def has_token?(token, kind=nil)
        k = @tokens[token][:kind]
        kind.nil? ? !k.nil? : k == kind
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

      # Tests if the given alias is really an alias.
      # 
      # @overload has_alias?(alias_name)
      #   Tests if the given alias is really an alias.
      #   @param [Symbol] alias_name the identifier of an alias
      #   @return [Boolean] +true+ if the given alias is really an alias,
      #     +false+ otherwise
      # @overload has_alias?(alias_name, kind)
      #   Tests if the given alias is really an alias.
      #   The kind will work as the expectation filter.
      #   @param [Symbol] alias_name the identifier of an alias
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Boolean] +true+ if the given alias is really an alias
      #     being a kind of the given kind, +false+ otherwise
      def has_alias?(alias_name, kind=nil)
        o = @tokens[alias_name]
        return false if o[:target].nil?
        kind.nil? ? true : o[:kind] == kind
      end

      # Reads all the true tokens (not aliases).
      # 
      # @return [Hash] the true tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_true_tokens
      #   Reads all the true tokens (not aliases).
      #   @return [Hash] the true tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_true_tokens(kind)
      #   Reads all the true tokens (not aliases) of the given +kind+.
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the true tokens in a
      #     form of Hash (<tt>token => description</tt>)
      def get_true_tokens(kind=nil)
        t = @lazy_tokens
        t = t.select  { |token,data| data[:kind] == kind  } unless kind.nil?
        t.select      { |token,data| data[:target].nil?   }.
          map         { |token,data| data[:description]   }.
          to_h
      end

      # Reads all the aliases.
      # 
      # @return [Hash] the aliases in a
      #     form of Hash (<tt>alias => target</tt>)
      # @overload get_aliases
      #   Reads all the aliases.
      #   @return [Hash] the aliases in a
      #     form of Hash (<tt>alias => target</tt>)
      # @overload get_aliases(kind)
      #   Reads all the aliases of the given +kind+.
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the aliases in a
      #     form of Hash (<tt>alias => target</tt>)
      def get_aliases(kind=nil)
        t = @lazy_tokens
        t = t.select  { |token,data| data[:kind] == kind  } unless kind.nil?
        t.reject      { |token,data| data[:target].nil?   }.
          map         { |token,data| data[:target]        }.
          to_h
      end

      # Reads all the tokens in a way that it is possible to
      # distinguish true tokens from aliases.
      # 
      # @note True tokens have descriptions (String) and aliases
      #   have targets (Symbol) assigned.
      # @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description|target</tt>)
      # @overload get_raw_tokens
      #   Reads all the tokens in a way that it is possible to
      #   distinguish true tokens from aliases.
      #   @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description|target</tt>)
      # @overload get_raw_tokens(kind)
      #   Reads all the tokens of the given +kind+ in a way
      #   that it is possible to distinguish true tokens from aliases.
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description|target</tt>)
      def get_raw_tokens(kind=nil)
        t = @lazy_tokens
        t = t.select  { |token,data| data[:kind] == kind } unless kind.nil?
        t.map         { |token,data| data[:target] || data[:description]  }.
          to_h
      end

      # Reads all the tokens (including aliases).
      # 
      # @note Use {#get_raw_tokens} if you want to distinguish
      #   true tokens from aliases.
      # @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_tokens
      #   Reads all the tokens (including aliases).
      #   @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_tokens(kind)
      #   Reads all the tokens (including aliases) of the
      #   given +kind+.
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description</tt>)
      def get_tokens(kind=nil)
        t = @lazy_tokens
        t = t.select  { |token,data| data[:kind] == kind } unless kind.nil?
        t.map         { |token,data| data[:description]  }.
          to_h
      end

      # Gets a target token for the alias.
      # 
      # @return [Symbol,nil] the token that the given alias points to
      #   or +nil+ if it isn't really an alias
      # @overload get_target_for_alias(alias_name)
      #   Gets a target token for the alias.
      #   @param [Symbol] alias_name the identifier of an alias
      #   @return [Symbol,nil] the token that the given alias points to
      #     or +nil+ if it isn't really an alias
      # @overload get_target_for_alias(alias_name, kind)
      #   Gets a target token for the alias that's +kind+ is given.
      #   @param [Symbol] alias_name the identifier of an alias
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Symbol,nil] the token that the given alias points to
      #     or +nil+ if it isn't really an alias
      def get_target_for_alias(alias_name, kind=nil)
        @tokens[alias_name][:target]
      end

      # Gets a kind of the given token or alias.
      # 
      # @return [Symbol,nil] the kind of the given +token+
      #   or +nil+ if the token is unknown
      # @overload get_kind(token)
      #   Gets a kind of the given token or alias.
      #   @param [Symbol] token identifier of a token
      #   @return [Symbol,nil] the kind of the given +token+
      #     or +nil+ if the token is unknown
      # @overload get_kind(token, kind)
      #   Gets a kind of the given token or alias.
      #   The kind will work as the expectation filter.
      #   @param [Symbol] token identifier of a token
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Symbol,nil] the kind of the given +token+
      #     or +nil+ if the token is unknown
      def get_kind(token, kind=nil)
        k = @tokens[token][:kind]
        return k if (kind.nil? || kind == k)
        nil
      end

      # Gets a true token for the given identifier.
      # 
      # @note If the given +token+ is really an alias it will
      #   be resolved and the real token pointed by that alias
      #   will be returned.
      # @return [Symbol,nil] the true token for the given +token+
      #   or +nil+
      # @overload get_true_token(token)
      #   Gets a true token for the given +token+ identifier.
      #   @param [Symbol] token the identifier of a token
      #   @return [Symbol,nil] the true token for the given +token+
      #     or +nil+ if the token is unknown
      # @overload get_true_token(token, kind)
      #   Gets a true token for the given +token+ identifier and the
      #   given +kind+. The kind will work as the expectation filter.
      #   @param [Symbol] token the identifier of a token
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Symbol,nil] the true token for the given +token+
      #     or +nil+ if the token is unknown or is not a kind of the
      #     given +kind+
      def get_true_token(token, kind=nil)
        o = @tokens[token]
        k = o[:kind]
        return nil if k.nil?
        r = (o[:target] || token)
        return r if kind.nil?
        k == kind ? r : nil
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

      # Gets a description of a token or an alias.
      # @note If the token is really an alias it will resolve the alias first.
      # @return [String,nil] the string containing description of the given
      #   token (which may be an alias) or +nil+ if the token is unknown
      # @overload get_description(token)
      #   Gets a description of a token or an alias.
      #   @param [Symbol] token the identifier of a token
      #   @return [String,nil] the string containing description of the given
      #     token (which may be an alias) or +nil+ if the token is unknown
      # @overload get_description(token, kind)
      #   Gets a description of a token or an alias of the given +kind+
      #   @param [Symbol] token the identifier of a token
      #   @param [Symbol] kind the identifier of a kind
      #   @return [String,nil] the string containing description of the given
      #     token (which may be an alias) or +nil+ if the token is unknown
      def get_description(token, kind=nil)
        @tokens[token][:description] if (kind.nil? || @tokens[token][:kind] == kind)
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
