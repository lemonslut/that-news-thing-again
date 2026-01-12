namespace :users do
  desc "Bootstrap the default admin user"
  task bootstrap: :environment do
    email = "lemonslut11@gmail.com"
    password = SecureRandom.alphanumeric(16)

    user = User.find_or_initialize_by(email_address: email)
    user.password = password
    user.provider = "email"
    user.allowed = true
    user.save!
    user.regenerate_api_token!

    puts "=" * 50
    puts "User bootstrapped:"
    puts "  Email:     #{user.email_address}"
    puts "  Password:  #{password}"
    puts "  API Token: #{user.api_token}"
    puts "=" * 50
  end

  desc "Allow a user by GitHub username or email"
  task :allow, [:identifier] => :environment do |_t, args|
    identifier = args[:identifier]

    if identifier.blank?
      puts "Usage: rake users:allow[github_username_or_email]"
      exit 1
    end

    user = User.find_by(github_username: identifier) || User.find_by(email_address: identifier.downcase)

    if user.nil?
      puts "User not found: #{identifier}"
      puts "The user must sign in with GitHub first to create their account."
      exit 1
    end

    user.update!(allowed: true)
    puts "User #{user.github_username || user.email_address} is now allowed to access the admin."
  end

  desc "Revoke access for a user by GitHub username or email"
  task :revoke, [:identifier] => :environment do |_t, args|
    identifier = args[:identifier]

    if identifier.blank?
      puts "Usage: rake users:revoke[github_username_or_email]"
      exit 1
    end

    user = User.find_by(github_username: identifier) || User.find_by(email_address: identifier.downcase)

    if user.nil?
      puts "User not found: #{identifier}"
      exit 1
    end

    user.update!(allowed: false)
    puts "User #{user.github_username || user.email_address} access has been revoked."
  end

  desc "List all users"
  task list: :environment do
    users = User.order(:created_at)

    if users.empty?
      puts "No users found."
    else
      puts "%-30s %-20s %-10s %-10s" % ["Email", "GitHub", "Allowed", "Provider"]
      puts "-" * 75
      users.each do |user|
        puts "%-30s %-20s %-10s %-10s" % [
          user.email_address.truncate(28),
          user.github_username || "-",
          user.allowed? ? "Yes" : "No",
          user.provider
        ]
      end
    end
  end
end
