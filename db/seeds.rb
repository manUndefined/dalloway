puts "Cleaning database..."

Message.destroy_all
Chat.destroy_all
Application.destroy_all
Offer.destroy_all
User.destroy_all


puts "Creating users..."

user1 = User.create!(
  email: "alice@test.com",
  password: "123456",
  first_name: "Alice",
  last_name: "Martin"
)

user2 = User.create!(
  email: "bob@test.com",
  password: "123456",
  first_name: "Bob",
  last_name: "Durand"
)

puts "Creating offers..."

offer1 = Offer.create!(
  title: "Junior Ruby Developer",
  description: "Looking for a junior Ruby on Rails developer",
  url: "https://fr.indeed.com/jobs?q=d%C3%A9veloppeur+full+stack&l=Lyon+%2869%29&radius=25&from=searchOnDesktopSerp%2Cwhatautocomplete%2CwhatautocompleteSourceStandard&vjk=1249543b086675bd&advn=4306931687063514"
)

offer2 = Offer.create!(
  title: "Backend Developer",
  description: "Backend role with Ruby and APIs",
  url: "https://fr.indeed.com/jobs?q=d%C3%A9veloppeur+full+stack&l=Lyon+%2869%29&radius=25&from=searchOnDesktopSerp%2Cwhatautocomplete%2CwhatautocompleteSourceStandard&vjk=ada48ca7b283fd59&advn=7182735776839034"
)

puts "Creating applications..."

application1 = Application.create!(
  user_id: user1.id,
  offer_id: offer1.id,
  cover_letter: "I would love to join your team!",
  status: "pending"
)

application2 = Application.create!(
  user_id: user2.id,
  offer_id: offer2.id,
  cover_letter: "My experience fits perfectly.",
  status: "accepted"
)

puts "Creating chats..."

chat1 = Chat.create!(
  user_id: user1.id,
  offer_id: offer1.id,
  title: "Discussion about the role"
)

puts "Creating messages..."

Message.create!(
  chat: chat1,
  content: "Hello, I have a question about the job.",
  role: "user"
)

Message.create!(
  chat: chat1,
  content: "Sure! What would you like to know?",
  role: "assistant"
)

puts "Seeding finished!"