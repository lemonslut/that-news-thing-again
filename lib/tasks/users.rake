namespace :users do
  desc "Create or reset the default user (lemonslut11@gmail.com)"
  task bootstrap: :environment do
    email = "lemonslut11@gmail.com"
    password = SecureRandom.hex(16)

    user = User.find_or_initialize_by(email_address: email)
    user.password = password
    user.save!

    puts "Email:    #{user.email_address}"
    puts "Password: #{password}"
    puts "Token:    #{user.api_token}"
  end
end
