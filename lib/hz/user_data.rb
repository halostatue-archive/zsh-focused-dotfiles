# frozen_string_literal: true

require_relative 'config'

class Hz::UserData < ::Hz
  DEFAULT_USER_DATA = {
    "name"               => "Name",
    "email"              => "Email",
    "github.user"        => "GitHub User",
    "github.oauth_token" => "GitHub OAuth Token",
    "hoe.travis_token"   => "Hoe Travis Token",
    "hoe.email.address"  => "Hoe Email Address",
    "hoe.email.password" => "Hoe Email Password"
  }

  def run
    require_user_file
    ask_user_data_by_keys(DEFAULT_USER_DATA.keys)
    ask_user_data_by_keys(deep_keys(user_data) - DEFAULT_USER_DATA.keys)

    cli.say "\n"

    while cli.agree('Add additional data? ') { |q| q.default = 'n' } do
      key = cli.ask('Enter new key name: ')

      if key.nil? or key.empty?
        cli.say 'No key provided. Aborting.'
        break
      else
        ask_user_data(key)
      end
    end

    deep_keys(user_data).each do |key_path|
      value = user_data_lookup(key_path)
      user_data.delete(key_path) if value.nil? or value.empty?
    end

    cli.say("\n%-30s\t%-40s\n" % %W(Key Value))
    cli.say("------------------------------\t----------------------------------------\n")
    deep_keys(user_data).each do |key_path|
      cli.say("%-30s\t%-40s\n" % [ key_path.gsub(/\./, ' '), user_data_lookup(key_path) ])
    end

    cli.say "\n"

    if cli.agree('Save this data? ') { |q| q.default = 'n' }
      write_user_data
      cli.say 'Saved.'
    else
      cli.say 'Not saved.'
    end
  end

  private

  def ask_user_data_by_keys(keys)
    keys.each { |key| ask_user_data(key) }
  end

  def ask_user_data(key)
    data = user_data_lookup(key)

    if data.respond_to?(:each_key)
      data.each_key { |k| ask_user_data("#{key}.#{k}") }
    else
      message = DEFAULT_USER_DATA[key] || key.gsub(/\./, ' ')
      value = cli.ask("#{message}: ") { |q| q.default = data }.to_s
      user_data_set(key, value)
    end
  end

  def write_user_data
    data = user_data.to_yaml rescue ''
    user_data_file.write(data)
  end

  def deep_keys(data, prefix = nil)
    data.map { |k, v|
      k = "#{prefix}#{k}"
      v.kind_of?(::Hash) ? deep_keys(v, "#{k}.") : k
    }.flatten
  end

  def require_user_file
    user_file.mkpath unless user_file.exist?
    user_data_file.write('') unless user_data_file.exist?
  end
end
