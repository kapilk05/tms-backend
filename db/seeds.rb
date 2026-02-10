Role.find_or_create_by(name: 'admin')
Role.find_or_create_by(name: 'manager')
Role.find_or_create_by(name: 'user')

puts "Roles created!"
