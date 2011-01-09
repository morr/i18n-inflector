# encoding: utf-8

require 'i18n'
require 'i18n-inflector/version'
require 'i18n-inflector/errors'
require 'i18n-inflector/inflector'

I18n::Backend::Simple.send(:include, I18n::Backend::Inflector)

require 'i18n-inflector/shortcuts'
