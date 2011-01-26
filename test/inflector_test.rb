require 'test_helper'

class I18nInflectorTest < Test::Unit::TestCase
  class Backend < I18n::Backend::Simple
    include I18n::Backend::Inflector
    include I18n::Backend::Fallbacks
  end

  def setup
    I18n.backend = Backend.new
    store_translations(:xx, :i18n => { :inflections => {
                                            :gender => {
                                              :m => 'male',
                                              :f => 'female',
                                              :n => 'neuter',
                                              :s => 'strange',
                                              :masculine  => '@m',
                                              :feminine   => '@f',
                                              :neuter     => '@n',
                                              :neutral    => '@neuter',
                                              :default    => 'neutral' },
                                            :person => {
                                              :i   => 'I',
                                              :you => 'You'},
                                            :@gender => {
                                                :m => 'male',
                                                :f => 'female',
                                                :n => 'neuter',
                                                :s => 'strange',
                                                :masculine  => '@m',
                                                :feminine   => '@f',
                                                :neuter     => '@n',
                                                :neutral    => '@neuter',
                                                :default    => 'neutral' }
                                        }   })

    store_translations(:xx, 'welcome'       => 'Dear @{f:Lady|m:Sir|n:You|All}!')
    store_translations(:xx, 'named_welcome' => 'Dear @gender{f:Lady|m:Sir|n:You|All}!')
    I18n.locale = :en
  end

  test "backend inflector has methods to test its switches" do
    assert_equal true,  I18n.inflector.options.unknown_defaults   = true
    assert_equal false, I18n.inflector.options.excluded_defaults  = false
    assert_equal false, I18n.inflector.options.aliased_patterns   = false
    assert_equal false, I18n.inflector.options.raises             = false
    assert_equal false, I18n.backend.inflector.options.raises
    assert_equal true,  I18n.backend.inflector.options.unknown_defaults
    assert_equal false, I18n.backend.inflector.options.excluded_defaults
    assert_equal false, I18n.backend.inflector.options.aliased_patterns
  end

  test "backend inflector store_translations: regenerates inflection structures when translations are loaded" do
    store_translations(:xx, :i18n => { :inflections => { :gender => { :o => 'other' }}})
    store_translations(:xx, 'hi' => 'Dear @{f:Lady|o:Others|n:You|All}!')
    assert_equal 'Dear Others!',  I18n.t('hi', :gender => :o,       :locale => :xx)
    assert_equal 'Dear Lady!',    I18n.t('hi', :gender => :f,       :locale => :xx)
    assert_equal 'Dear You!',     I18n.t('hi', :gender => :unknown, :locale => :xx)
    assert_equal 'Dear All!',     I18n.t('hi', :gender => :m,       :locale => :xx)
  end

  test "backend inflector store_translations: raises I18n::DuplicatedInflectionToken when duplicated token is given" do
    assert_raise I18n::DuplicatedInflectionToken do
      store_translations(:xx, :i18n => { :inflections => { :gender => { :o => 'other' }, :person => { :o => 'o' }}})
    end
  end

  test "backend inflector strict store_translations: allows duplicated tokens across differend kinds" do
    assert_nothing_raised I18n::DuplicatedInflectionToken do
      store_translations(:xx, :i18n => { :inflections => { :@gender => { :o => 'other' }, :@person => { :o => 'o' }}})
      store_translations(:xx, :i18n => { :inflections => { :gender => { :o => 'other' },  :@gender => { :o => 'o' }}})
    end
  end

  test "backend inflector store_translations: raises I18n::BadInflectionAlias when bad alias is given" do
     assert_raise I18n::BadInflectionAlias do
       store_translations(:xx, :i18n => { :inflections => { :gender => { :o => '@nonexistant' }}})
     end
     assert_raise I18n::BadInflectionAlias do
       store_translations(:xx, :i18n => { :inflections => { :gender => { :default => '@nonexistant' }}})
     end
      assert_raise I18n::BadInflectionAlias do
        store_translations(:xx, :i18n => { :inflections => { :@gender => { :oh => '@nonex' }}})
      end
      assert_raise I18n::BadInflectionAlias do
        store_translations(:xx, :i18n => { :inflections => { :@gender => { :default => '@nonex' }}})
      end
  end

  test "backend inflector store_translations: raises I18n::BadInflectionToken when bad token is given" do
     assert_raise I18n::BadInflectionToken do
       store_translations(:xx, :i18n => { :inflections => { :gender => { :o => '@' }}})
       store_translations(:xx, :i18n => { :inflections => { :gender => { :tok => nil }}})
       store_translations(:xx, :i18n => { :inflections => { :@gender => { :o => '@' }}})
       store_translations(:xx, :i18n => { :inflections => { :@gender => { :tok => nil }}})
     end
  end

  test "backend inflector translate: allows pattern-only translation data" do
    store_translations(:xx, 'clear_welcome' => '@{f:Lady|m:Sir|n:You|All}')
    assert_equal 'Lady', I18n.t('clear_welcome', :gender => 'f', :locale => :xx)
    store_translations(:xx, 'clear_welcome' => '@gender{f:Lady|m:Sir|n:You|All}')
    assert_equal 'Lady', I18n.t('clear_welcome', :gender => 'f', :locale => :xx)
  end

  test "backend inflector translate: allows patterns to be escaped using @@ or \\@" do
    store_translations(:xx, 'escaped_welcome' => '@@{f:AAAAA|m:BBBBB}')
    assert_equal '@{f:AAAAA|m:BBBBB}', I18n.t('escaped_welcome', :gender => 'f', :locale => :xx)
    store_translations(:xx, 'escaped_welcome' => '\@{f:AAAAA|m:BBBBB}')
    assert_equal '@{f:AAAAA|m:BBBBB}', I18n.t('escaped_welcome', :gender => 'f', :locale => :xx)
  end

  test "backend inflector translate: picks Lady for :f gender option" do
    assert_equal 'Dear Lady!', I18n.t('welcome', :gender => :f, :locale => :xx)
  end

  test "backend inflector translate: picks Lady for f gender option" do
    assert_equal 'Dear Lady!', I18n.t('welcome', :gender => 'f', :locale => :xx)
  end

  test "backend inflector translate: picks Sir for :m gender option"  do
    assert_equal 'Dear Sir!', I18n.t('welcome', :gender => :m, :locale => :xx)
  end

  test "backend inflector translate: picks Sir for :masculine gender option" do
    assert_equal 'Dear Sir!', I18n.t('welcome', :gender => :masculine, :locale => :xx)
  end

  test "backend inflector translate: picks Sir for masculine gender option" do
    assert_equal 'Dear Sir!', I18n.t('welcome', :gender => 'masculine', :locale => :xx)
  end

  test "backend inflector translate: picks an empty string when no default token is present and no free text is there" do
    store_translations(:xx, 'none_welcome' => '@{n:You|f:Lady}')
    assert_equal '', I18n.t('none_welcome', :gender => 'masculine', :locale => :xx)
  end

  test "backend inflector translate: allows multiple patterns in the same data" do
    store_translations(:xx, 'multiple_welcome' => '@@{f:AAAAA|m:BBBBB} @{f:Lady|m:Sir|n:You|All} @{f:Lady|All}@{m:Sir|All}@{n:You|All}')
    assert_equal '@{f:AAAAA|m:BBBBB} Sir AllSirAll', I18n.t('multiple_welcome', :gender => 'masculine', :locale => :xx)
  end

  test "backend inflector translate: falls back to default for the unknown gender option" do
    assert_equal 'Dear You!', I18n.t('welcome', :gender => :unknown, :locale => :xx)
  end

  test "backend inflector translate: falls back to default for a gender option set to nil" do
    assert_equal 'Dear You!', I18n.t('welcome', :gender => nil, :locale => :xx)
  end

  test "backend inflector translate: falls back to default for no gender option" do
    assert_equal 'Dear You!', I18n.t('welcome', :locale => :xx)
  end

  test "backend inflector translate: falls back to free text for the proper gender option but not present in pattern" do
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :s, :locale => :xx)
  end

  test "backend inflector translate: falls back to free text when :inflector_unknown_defaults is false" do
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :unknown,  :locale => :xx, :inflector_unknown_defaults => false)
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :s,        :locale => :xx, :inflector_unknown_defaults => false)
    assert_equal 'Dear All!', I18n.t('welcome', :gender => nil,       :locale => :xx, :inflector_unknown_defaults => false)
  end

  test "backend inflector translate: falls back to default for no gender option when :inflector_unknown_defaults is false" do
    assert_equal 'Dear You!', I18n.t('welcome', :locale => :xx, :inflector_unknown_defaults => false)
  end

  test "backend inflector translate: falls back to free text for the unknown gender option when global inflector_unknown_defaults is false" do
    I18n.inflector.options.unknown_defaults = false
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :unknown, :locale => :xx)
  end

  test "backend inflector translate: falls back to default for the unknown gender option when global inflector_unknown_defaults is overriden" do
    I18n.inflector.options.unknown_defaults = false
    assert_equal 'Dear You!', I18n.t('welcome', :gender => :unknown, :locale => :xx, :inflector_unknown_defaults => true)
  end

  test "backend inflector translate: falls back to default token for ommited gender option when :inflector_excluded_defaults is true" do
    assert_equal 'Dear You!', I18n.t('welcome', :gender => :s, :locale => :xx, :inflector_excluded_defaults => true)
    I18n.inflector.options.excluded_defaults = true
    assert_equal 'Dear You!', I18n.t('welcome', :gender => :s, :locale => :xx)
  end

  test "backend inflector translate: falls back to free text for ommited gender option when :inflector_excluded_defaults is false" do
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :s, :locale => :xx, :inflector_excluded_defaults => false)
    I18n.inflector.options.excluded_defaults = false
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :s, :locale => :xx)
  end

  test "backend inflector translate: raises I18n::InvalidOptionForKind when bad kind is given and inflector_raises is true" do
    assert_nothing_raised I18n::InvalidOptionForKind do
      I18n.t('welcome', :locale => :xx, :inflector_raises => true)
    end
    tr = I18n.backend.send(:translations)
    tr[:xx][:i18n][:inflections][:gender].delete(:default)
    store_translations(:xx, :i18n => { :inflections => { :gender => { :o => 'other' }}})
    assert_raise(I18n::InflectionOptionNotFound)  { I18n.t('welcome', :locale => :xx, :inflector_raises => true) }
    assert_raise(I18n::InflectionOptionIncorrect) { I18n.t('welcome', :locale => :xx, :gender => "", :inflector_raises => true) }
    assert_raise(I18n::InflectionOptionIncorrect) { I18n.t('welcome', :locale => :xx, :gender => nil, :inflector_raises => true) }
    assert_raise I18n::InflectionOptionNotFound do
     I18n.inflector.options.raises = true
     I18n.t('welcome', :locale => :xx)
    end
  end

  test "backend inflector translate: raises I18n::InvalidInflectionToken when bad token is given and inflector_raises is true" do
    store_translations(:xx, 'hi' => 'Dear @{f:Lady|o:BAD_TOKEN|n:You|First}!')
    assert_raise(I18n::InvalidInflectionToken) { I18n.t('hi', :locale => :xx, :inflector_raises => true) }
    assert_raise I18n::InvalidInflectionToken do
      I18n.inflector.options.raises = true
      I18n.t('hi', :locale => :xx)
    end
  end

  test "backend inflector translate: raises I18n::MisplacedInflectionToken when bad token is given and inflector_raises is true" do
    store_translations(:xx, 'hi' => 'Dear @{f:Lady|i:Me|n:You|First}!')
    assert_raise(I18n::MisplacedInflectionToken) { I18n.t('hi', :locale => :xx, :inflector_raises => true) }
    assert_raise I18n::MisplacedInflectionToken do
      I18n.inflector.options.raises = true
      I18n.t('hi', :locale => :xx)
    end
  end

  test "backend inflector translate: works with %{} patterns" do
    store_translations(:xx, 'hi' => 'Dear @{f:Lady|m:%{test}}!')
    assert_equal 'Dear Dude!', I18n.t('hi', :gender => :m, :locale => :xx, :test => "Dude")
  end

  test "backend inflector translate: works with tokens separated by commas" do
    store_translations(:xx, 'hi' => 'Dear @{f,m:Someone|n:You|All}!')
    assert_equal 'Dear Someone!', I18n.t('hi', :gender => :m, :locale => :xx)
  end

  test "backend inflector translate: works with negative tokens" do
    store_translations(:xx, 'hi' => 'Dear @{!m:Lady|m:Sir|n:You|All}!')
    assert_equal 'Dear Lady!',    I18n.t('hi', :gender => :n, :locale => :xx)
    assert_equal 'Dear Sir!',     I18n.t('hi', :gender => :m, :locale => :xx)
    assert_equal 'Dear Lady!',    I18n.t('hi', :locale => :xx)
    assert_equal 'Dear Lady!',    I18n.t('hi', :gender => :unknown, :locale => :xx)
    store_translations(:xx, 'hi' => 'Hello @{!m:Ladies|n:You}')
    assert_equal 'Hello Ladies',  I18n.t('hi', :gender => :n, :locale => :xx)
    assert_equal 'Hello Ladies',  I18n.t('hi', :gender => :f, :locale => :xx)
    assert_equal 'Hello ',        I18n.t('hi', :gender => :m, :locale => :xx)
    assert_equal 'Hello Ladies',  I18n.t('hi', :locale => :xx)
    store_translations(:xx, 'hi' => 'Hello @{!n:Ladies|m,f:You}')
    assert_equal 'Hello ',  I18n.t('hi', :locale => :xx, :inflector_raises => true)
  end

  test "backend inflector translate: works with tokens separated by commas and negative tokens" do
    store_translations(:xx, 'hi' => 'Dear @{!f,!m:Someone|m:Sir}!')
    assert_equal 'Dear Someone!', I18n.t('hi', :gender => :m, :locale => :xx)
    assert_equal 'Dear Someone!', I18n.t('hi', :gender => :n, :locale => :xx)
    store_translations(:xx, 'hi' => 'Dear @{!f,!m,n:Someone|m:Sir}!')
    assert_equal 'Dear Someone!', I18n.t('hi', :gender => :m, :locale => :xx)
    assert_equal 'Dear Someone!', I18n.t('hi', :gender => :n, :locale => :xx)
    store_translations(:xx, 'hi' => 'Dear @{!f,n:Someone|m:Sir|f:Lady}!')
    assert_equal 'Dear Someone!', I18n.t('hi', :gender => :m, :locale => :xx)
    assert_equal 'Dear Lady!',    I18n.t('hi', :gender => :f, :locale => :xx)
    assert_equal 'Dear Someone!', I18n.t('hi', :locale => :xx)
  end

  test "backend inflector translate: works with aliased patterns" do
    store_translations(:xx, 'hi' => 'Dear @{masculine:Sir|feminine:Lady|n:You|All}!')
    assert_equal 'Dear Sir!',   I18n.t('hi', :gender => :m,         :locale => :xx, :inflector_aliased_patterns => true)
    assert_equal 'Dear Sir!',   I18n.t('hi', :gender => :masculine, :locale => :xx, :inflector_aliased_patterns => true)
    assert_equal 'Dear Lady!',  I18n.t('hi', :gender => :f,         :locale => :xx, :inflector_aliased_patterns => true)
    assert_equal 'Dear All!',   I18n.t('hi', :gender => :s,         :locale => :xx, :inflector_aliased_patterns => true)
    assert_equal 'Dear You!',   I18n.t('hi', :locale => :xx, :inflector_aliased_patterns => true)
    I18n.inflector.options.aliased_patterns = true
    assert_equal 'Dear Sir!', I18n.t('hi', :gender => :masculine, :locale => :xx)
  end

  test "backend inflector translate: recognizes named patterns and strict kinds" do
    store_translations(:xx, :i18n => { :inflections => { :@gender => { :s => 'sir', :o => 'other', :s => 'a', :n => 'n', :default => 'n' }}})
    store_translations(:xx, 'hi'  => 'Dear @gender{s:Sir|o:Other|n:You|All}!')
    assert_equal 'Dear Sir!',   I18n.t('hi', :gender  => :s,       :locale => :xx)
    assert_equal 'Dear Other!', I18n.t('hi', :gender  => :o,       :locale => :xx)
    assert_equal 'Dear You!',   I18n.t('hi',                       :locale => :xx)
    assert_equal 'Dear You!',   I18n.t('hi', :gender  => "",       :locale => :xx)
    assert_equal 'Dear You!',   I18n.t('hi', :gender  => :unknown, :locale => :xx)
    assert_equal 'Dear You!',   I18n.t('hi', :@gender => :unknown, :locale => :xx)
  end

  test "backend inflector translate: prioritizes @-style kinds in options for named patterns" do
    store_translations(:xx, :i18n => { :inflections => { :@gender => { :s => 'sir', :o => 'other', :s => 'a', :n => 'n', :default => 'n' }}})
    store_translations(:xx, 'hi'  => 'Dear @gender{s:Sir|o:Other|n:You|All}!')
    assert_equal 'Dear Sir!',   I18n.t('hi', :gender => :s,                       :locale => :xx)
    assert_equal 'Dear You!',   I18n.t('hi', :gender => :s, :@gender => :unknown, :locale => :xx)
    assert_equal 'Dear You!',   I18n.t('hi', :gender => :s, :@gender => nil,      :locale => :xx)
    assert_equal 'Dear Sir!',   I18n.t('hi', :gender => :s, :@gender => :s,       :locale => :xx)

  end

  test "inflector inflected_locales: lists languages that support inflection" do
    assert_equal [:xx], I18n.inflector.inflected_locales
    assert_equal [:xx], I18n.inflector.inflected_locales(:gender)
  end

  test "inflector.strict inflected_locales: lists languages that support inflection" do
    assert_equal [:xx], I18n.inflector.strict.inflected_locales
    assert_equal [:xx], I18n.inflector.strict.inflected_locales(:gender)
  end

  test "inflector inflected_locale?: tests if the given locale supports inflection" do
    assert_equal true, I18n.inflector.inflected_locale?(:xx)
    I18n.locale = :xx
    assert_equal true, I18n.inflector.inflected_locale?
  end

  test "inflector.strict inflected_locale?: tests if the given locale supports inflection" do
    assert_equal true, I18n.inflector.strict.inflected_locale?(:xx)
    I18n.locale = :xx
    assert_equal true, I18n.inflector.strict.inflected_locale?
  end

  test "inflector new_database creates a database with inflections" do
    assert_kind_of I18n::Inflector::InflectionData, I18n.inflector.new_database(:yy)
    assert_equal true,  I18n.inflector.inflected_locale?(:yy)
    assert_equal false, I18n.inflector.inflected_locale?(:yyyyy)
  end

  test "inflector add_database adds existing database with inflections" do
    db = I18n::Inflector::InflectionData.new(:zz)
    assert_kind_of I18n::Inflector::InflectionData, I18n.inflector.add_database(db)
    assert_equal true,  I18n.inflector.inflected_locale?(:zz)
    assert_equal false, I18n.inflector.inflected_locale?(:zzzzzz)
  end

  test "inflector delete_database deletes existing inflections database" do
    I18n.inflector.new_database(:vv)
    assert_equal true,        I18n.inflector.inflected_locale?(:vv)
    assert_kind_of NilClass,  I18n.inflector.delete_database(:vv)
    assert_equal false,       I18n.inflector.inflected_locale?(:vv)
  end

  test "inflector locale_supported?: checks if a language supports inflection" do
    assert_equal true,  I18n.inflector.locale_supported?(:xx)
    assert_equal false, I18n.inflector.locale_supported?(:pl)
    assert_equal false, I18n.inflector.locale_supported?(nil)
    assert_equal false, I18n.inflector.locale_supported?("")
    I18n.locale = :xx
    assert_equal true,  I18n.inflector.locale_supported?
    I18n.locale = :pl
    assert_equal false, I18n.inflector.locale_supported?
    I18n.locale = nil
    assert_equal false, I18n.inflector.locale_supported?
    I18n.locale = ""
    assert_equal false, I18n.inflector.locale_supported?
  end

  test "inflector.strict locale_supported?: checks if a language supports inflection" do
    assert_equal true,  I18n.inflector.strict.locale_supported?(:xx)
    assert_equal false, I18n.inflector.strict.locale_supported?(:pl)
    assert_equal false, I18n.inflector.strict.locale_supported?(nil)
    assert_equal false, I18n.inflector.strict.locale_supported?("")
    I18n.locale = :xx
    assert_equal true,  I18n.inflector.strict.locale_supported?
    I18n.locale = :pl
    assert_equal false, I18n.inflector.strict.locale_supported?
    I18n.locale = nil
    assert_equal false, I18n.inflector.strict.locale_supported?
    I18n.locale = ""
    assert_equal false, I18n.inflector.strict.locale_supported?
  end

  test "inflector has_token?: checks if a token exists" do
    assert_equal true, I18n.inflector.has_token?(:neuter, :gender, :xx)
    assert_equal true, I18n.inflector.has_token?(:neuter, :xx)
    assert_equal true, I18n.inflector.has_token?(:f,      :xx)
    assert_equal true, I18n.inflector.has_token?(:you,    :xx)
    I18n.locale = :xx
    assert_equal true, I18n.inflector.has_token?(:f)
    assert_equal true, I18n.inflector.has_token?(:you)  
    assert_equal false,I18n.inflector.has_token?(:faafaffafafa)
  end

  test "inflector.strict has_token?: checks if a token exists" do
    assert_equal true,  I18n.inflector.strict.has_token?(:neuter,  :gender, :xx)
    assert_equal true,  I18n.inflector.strict.has_token?(:f,       :gender, :xx)
    assert_equal false, I18n.inflector.strict.has_token?(:you,     :gender)
    I18n.locale = :xx
    assert_equal true,  I18n.inflector.strict.has_token?(:f,       :gender)
    assert_equal false, I18n.inflector.strict.has_token?(:you,     :gender)  
    assert_equal false, I18n.inflector.strict.has_token?(:faafaffafafa)
  end

  test "inflector has_kind?: checks if an inflection kind exists" do
    assert_equal true,  I18n.inflector.has_kind?(:gender, :xx)
    assert_equal true,  I18n.inflector.has_kind?(:person, :xx)
    assert_equal false, I18n.inflector.has_kind?(:nonono, :xx)
    assert_equal false, I18n.inflector.has_kind?(nil,     :xx)
    I18n.locale = :xx
    assert_equal true,  I18n.inflector.has_kind?(:gender)
    assert_equal true,  I18n.inflector.has_kind?(:person)
    assert_equal false, I18n.inflector.has_kind?(:faafaffafafa)
  end

  test "inflector.strict has_kind?: checks if an inflection kind exists" do
    assert_equal true,  I18n.inflector.strict.has_kind?(:gender, :xx)
    assert_equal false, I18n.inflector.strict.has_kind?(:person, :xx)
    assert_equal false, I18n.inflector.strict.has_kind?(nil,     :xx)
    I18n.locale = :xx
    assert_equal true,  I18n.inflector.strict.has_kind?(:gender)
    assert_equal false, I18n.inflector.strict.has_kind?(nil)  
    assert_equal false, I18n.inflector.strict.has_kind?(:faafaffa)
  end

  test "inflector kind: checks what is the inflection kind of the given token" do
    assert_equal :gender, I18n.inflector.kind(:neuter,  :xx)
    assert_equal :gender, I18n.inflector.kind(:f,       :xx)
    assert_equal :person, I18n.inflector.kind(:you,     :xx)
    assert_equal nil,     I18n.inflector.kind(nil,      :xx)
    assert_equal nil,     I18n.inflector.kind(nil,      nil)
    assert_equal nil,     I18n.inflector.kind(:nononono,:xx)
    I18n.locale = :xx
    assert_equal :gender, I18n.inflector.kind(:neuter)
    assert_equal :gender, I18n.inflector.kind(:f)
    assert_equal :person, I18n.inflector.kind(:you)  
    assert_equal nil,     I18n.inflector.kind(nil)
    assert_equal nil,     I18n.inflector.kind(:faafaffa)
  end

  test "inflector.strict kind: checks what is the inflection kind of the given token" do
    assert_equal :gender, I18n.inflector.strict.kind(:neuter,  :gender,  :xx)
    assert_equal :gender, I18n.inflector.strict.kind(:f,       :gender,  :xx)
    assert_equal nil, I18n.inflector.strict.kind(:f,           :nontrue, :xx)
    assert_equal nil, I18n.inflector.strict.kind(:f,           nil,      :xx)
    assert_equal nil, I18n.inflector.strict.kind(nil,          :gender,  :xx)
    assert_equal nil, I18n.inflector.strict.kind(nil,          nil,      :xx)
    assert_equal nil, I18n.inflector.strict.kind(:faafaffafafa, nil,     :xx)
    assert_equal nil, I18n.inflector.strict.kind(:nil,         :faafafa, :xx)
    I18n.locale = :xx
    assert_equal :gender, I18n.inflector.strict.kind(:neuter,  :gender)
    assert_equal :gender, I18n.inflector.strict.kind(:f,       :gender)
    assert_equal nil,     I18n.inflector.strict.kind(:f,       :nontrue)
    assert_equal nil,     I18n.inflector.strict.kind(nil,      :gender)
    assert_equal nil,     I18n.inflector.strict.kind(nil,      nil)
    assert_equal nil,     I18n.inflector.strict.kind(:faafaffa)
  end

  test "inflector true_token: gets true token for the given token name" do
    assert_equal :n,  I18n.inflector.true_token(:neuter, :xx)
    assert_equal :f,  I18n.inflector.true_token(:f, :xx)
    I18n.locale = :xx
    assert_equal :n,  I18n.inflector.true_token(:neuter)
    assert_equal :f,  I18n.inflector.true_token(:f)
    assert_equal :f,  I18n.inflector.true_token(:f, :xx)
    assert_equal nil, I18n.inflector.true_token(:f, :person, :xx)
    assert_equal nil, I18n.inflector.true_token(:f, :nokind, :xx)
    assert_equal nil, I18n.inflector.true_token(:faafaffa)
  end

  test "inflector.strict true_token: gets true token for the given token name" do
    assert_equal :n,  I18n.inflector.strict.true_token(:neuter,  :gender,  :xx )
    assert_equal :f,  I18n.inflector.strict.true_token(:f,       :gender,  :xx )
    I18n.locale = :xx
    assert_equal :n,  I18n.inflector.strict.true_token(:neuter,  :gender       )
    assert_equal :f,  I18n.inflector.strict.true_token(:f,       :gender       )
    assert_equal :f,  I18n.inflector.strict.true_token(:f,       :gender,  :xx )
    assert_equal nil, I18n.inflector.strict.true_token(:f,       :person,  :xx )
    assert_equal nil, I18n.inflector.strict.true_token(:f,       nil,      :xx )
    assert_equal nil, I18n.inflector.strict.true_token(:faafaffa)
  end

  test "inflector has_true_token?: tests if true token exists for the given token name" do
    assert_equal false, I18n.inflector.has_true_token?(:neuter, :xx         )
    assert_equal true,  I18n.inflector.has_true_token?(:f,      :xx         )
    I18n.locale = :xx
    assert_equal false, I18n.inflector.has_true_token?(:neuter              )
    assert_equal true,  I18n.inflector.has_true_token?(:f                   )
    assert_equal true,  I18n.inflector.has_true_token?(:f,      :xx         )
    assert_equal false, I18n.inflector.has_true_token?(:f,      :person, :xx)
    assert_equal false, I18n.inflector.has_true_token?(:f,      :nokind, :xx)
    assert_equal false, I18n.inflector.has_true_token?(:faafaff)
  end

  test "inflector strict markers: tests if named markers in kinds are working for API calls" do
    tt= {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange"}
    t = tt.merge({:masculine=>"male",:feminine=>"female",:neuter=>"neuter",:neutral=>"neuter"})
    al= {:masculine=>:m,:feminine=>:f,:neuter=>:n,:neutral=>:n}
    tr= tt.merge(al)
    assert_equal [:xx],   I18n.inflector.inflected_locales(           :@gender      )
    assert_equal t,       I18n.inflector.tokens(                      :@gender, :xx )
    assert_equal tt,      I18n.inflector.true_tokens(                 :@gender, :xx )
    assert_equal tr,      I18n.inflector.raw_tokens(                  :@gender, :xx )
    assert_equal :n,      I18n.inflector.default_token(               :@gender, :xx )
    assert_equal al,      I18n.inflector.aliases(                     :@gender, :xx )
    assert_equal true,    I18n.inflector.has_kind?(                   :@gender, :xx )
    assert_equal true,    I18n.inflector.has_alias?(        :neuter,  :@gender, :xx )
    assert_equal true,    I18n.inflector.has_token?(        :n,       :@gender, :xx )
    assert_equal false,   I18n.inflector.has_true_token?(   :neuter,  :@gender, :xx )
    assert_equal true,    I18n.inflector.has_true_token?(   :n,       :@gender, :xx )
    assert_equal :n,      I18n.inflector.true_token(        :neuter,  :@gender, :xx )
    assert_equal "neuter",I18n.inflector.token_description( :neuter,  :@gender, :xx )
    assert_equal "neuter",I18n.inflector.token_description( :n,       :@gender, :xx )
    I18n.locale = :xx
    assert_equal t,       I18n.inflector.tokens(                      :@gender      )
    assert_equal tt,      I18n.inflector.true_tokens(                 :@gender      )
    assert_equal tr,      I18n.inflector.raw_tokens(                  :@gender      )
    assert_equal :n,      I18n.inflector.default_token(               :@gender      )
    assert_equal al,      I18n.inflector.aliases(                     :@gender      )
    assert_equal true,    I18n.inflector.has_kind?(                   :@gender      )
    assert_equal true,    I18n.inflector.has_alias?(        :neuter,  :@gender      )
    assert_equal true,    I18n.inflector.has_token?(        :n,       :@gender      )
    assert_equal false,   I18n.inflector.has_true_token?(   :neuter,  :@gender      )
    assert_equal true,    I18n.inflector.has_true_token?(   :n,       :@gender      )
    assert_equal :n,      I18n.inflector.true_token(        :neuter,  :@gender      )
    assert_equal "neuter",I18n.inflector.token_description( :neuter,  :@gender      )
    assert_equal "neuter",I18n.inflector.token_description( :n,       :@gender      )
  end

  test "inflector.strict has_true_token?: tests if true token exists for the given token name" do
    assert_equal false, I18n.inflector.strict.has_true_token?(:neuter, :gender,  :xx )
    assert_equal true,  I18n.inflector.strict.has_true_token?(:f,      :gender,  :xx )
    I18n.locale = :xx
    assert_equal false, I18n.inflector.strict.has_true_token?(:neuter, :gender       )
    assert_equal true,  I18n.inflector.strict.has_true_token?(:f,      :gender       )
    assert_equal true,  I18n.inflector.strict.has_true_token?(:f,      :gender,  :xx )
    assert_equal false, I18n.inflector.strict.has_true_token?(:f,      :person,  :xx )
    assert_equal false, I18n.inflector.strict.has_true_token?(:f,      nil,      :xx )
    assert_equal false, I18n.inflector.strict.has_true_token?(:faafaff)
  end

  test "inflector kinds: lists inflection kinds" do
    assert_not_nil I18n.inflector.kinds(:xx)
    assert_equal [:gender,:person], I18n.inflector.kinds(:xx).sort{|k,v| k.to_s<=>v.to_s}
    I18n.locale = :xx
    assert_equal [:gender,:person], I18n.inflector.kinds.sort{|k,v| k.to_s<=>v.to_s}
  end

  test "inflector.strict kinds: lists inflection kinds" do
    assert_not_nil I18n.inflector.strict.kinds(:xx)
    assert_equal [:gender], I18n.inflector.strict.kinds(:xx)
    I18n.locale = :xx
    assert_equal [:gender], I18n.inflector.strict.kinds
  end

  test "inflector tokens: lists all inflection tokens including aliases" do
    h = {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange",
         :masculine=>"male",:feminine=>"female",:neuter=>"neuter",
         :neutral=>"neuter"}
    ha = h.merge(:i=>'I', :you=>'You')
    assert_equal h,   I18n.inflector.tokens(:gender, :xx)
    I18n.locale = :xx
    assert_equal h,   I18n.inflector.tokens(:gender)
    assert_equal ha,  I18n.inflector.tokens
  end

  test "inflector.strict tokens: lists all inflection tokens including aliases" do
    h = {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange",
         :masculine=>"male",:feminine=>"female",:neuter=>"neuter",
         :neutral=>"neuter"}
    assert_equal h,   I18n.inflector.strict.tokens(:gender, :xx)
    I18n.locale = :xx
    assert_equal h,   I18n.inflector.strict.tokens(:gender)
    assert_equal Hash.new, I18n.inflector.strict.tokens
  end

  test "inflector true_tokens: lists true tokens" do
    h  = {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange"}
    ha = h.merge(:i=>"I",:you=>"You")
    assert_equal h,   I18n.inflector.true_tokens(:gender, :xx)
    I18n.locale = :xx
    assert_equal h,   I18n.inflector.true_tokens(:gender)
    assert_equal ha,  I18n.inflector.true_tokens
  end

  test "inflector.strict true_tokens: lists true tokens" do
    h  = {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange"}
    assert_equal h,   I18n.inflector.strict.true_tokens(:gender, :xx)
    I18n.locale = :xx
    assert_equal h,   I18n.inflector.strict.true_tokens(:gender)
    assert_equal Hash.new, I18n.inflector.strict.true_tokens
  end

  test "inflector raw_tokens: lists tokens in a so called raw format" do
    h = {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange",
         :masculine=>:m,:feminine=>:f,:neuter=>:n,
         :neutral=>:n}
    ha = h.merge(:i=>'I',:you=>"You")
    assert_equal h,   I18n.inflector.raw_tokens(:gender, :xx)
    I18n.locale = :xx
    assert_equal h,   I18n.inflector.raw_tokens(:gender)
    assert_equal ha,  I18n.inflector.raw_tokens    
  end

  test "inflector.strict raw_tokens: lists tokens in a so called raw format" do
    h = {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange",
         :masculine=>:m,:feminine=>:f,:neuter=>:n,
         :neutral=>:n}
    assert_equal h,   I18n.inflector.strict.raw_tokens(:gender, :xx)
    I18n.locale = :xx
    assert_equal h,   I18n.inflector.strict.raw_tokens(:gender)
    assert_equal Hash.new, I18n.inflector.strict.raw_tokens    
  end

  test "inflector default_token: returns a default token for a kind" do
    assert_equal :n, I18n.inflector.default_token(:gender, :xx)
    I18n.locale = :xx
    assert_equal :n, I18n.inflector.default_token(:gender)
  end

  test "inflector.strict default_token: returns a default token for a kind" do
    assert_equal :n, I18n.inflector.strict.default_token(:gender, :xx)
    I18n.locale = :xx
    assert_equal :n, I18n.inflector.strict.default_token(:gender)
  end

  test "inflector aliases: lists aliases" do
    a = {:masculine=>:m, :feminine=>:f, :neuter=>:n, :neutral=>:n}
    assert_equal a, I18n.inflector.aliases(:gender, :xx)
    I18n.locale = :xx
    assert_equal a, I18n.inflector.aliases(:gender)
    assert_equal a, I18n.inflector.aliases
  end

  test "inflector.strict aliases: lists aliases" do
    a = {:masculine=>:m, :feminine=>:f, :neuter=>:n, :neutral=>:n}
    assert_equal a, I18n.inflector.strict.aliases(:gender, :xx)
    I18n.locale = :xx
    assert_equal a, I18n.inflector.strict.aliases(:gender)
    assert_equal Hash.new, I18n.inflector.strict.aliases
  end

  test "inflector token_description: returns token's description" do
    assert_equal "male",    I18n.inflector.token_description(:m, :xx)
    I18n.locale = :xx
    assert_equal "male",    I18n.inflector.token_description(:m)
    assert_equal nil,       I18n.inflector.token_description(:nonexistent,  :xx)
    assert_equal "neuter",  I18n.inflector.token_description(:neutral,      :xx)
  end

  test "inflector.strict token_description: returns token's description" do
    assert_equal "male",    I18n.inflector.strict.token_description(:m, :gender, :xx)
    I18n.locale = :xx
    assert_equal "male",    I18n.inflector.strict.token_description(:m,            :gender)
    assert_equal nil,       I18n.inflector.strict.token_description(:nonexistent,  :gender, :xx)
    assert_equal "neuter",  I18n.inflector.strict.token_description(:neutral,      :gender, :xx)
  end

  test "inflector has_alias?: tests whether a token is an alias" do
      assert_equal true,  I18n.inflector.has_alias?(:neutral, :xx)
      assert_equal false, I18n.inflector.has_alias?(:you,     :xx)
      assert_equal true,  I18n.inflector.has_alias?(:neutral, :gender, :xx)
      assert_equal false, I18n.inflector.has_alias?(:you,     :gender, :xx)
      assert_equal false, I18n.inflector.has_alias?(:neutral, :nokind, :xx)
      I18n.locale = :xx
      assert_equal true,  I18n.inflector.has_alias?(:neutral)
  end

  test "inflector.strict has_alias?: tests whether a token is an alias" do
      assert_equal true,  I18n.inflector.strict.has_alias?(:neutral, :gender, :xx)
      assert_equal false, I18n.inflector.strict.has_alias?(:you,     :person, :xx)
      assert_equal false, I18n.inflector.strict.has_alias?(:you,     :gender, :xx)
      I18n.locale = :xx
      assert_equal true,  I18n.inflector.strict.has_alias?(:neutral, :gender)
  end

end
