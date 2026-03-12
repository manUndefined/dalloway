puts "Cleaning database..."
Message.destroy_all
Chat.destroy_all
Offer.destroy_all
Application.destroy_all
User.destroy_all

puts "Setting up users..."
users = User.all.to_a
if users.empty?
  users = [User.create!(
    email: "laye@dalloway.com",
    password: "password",
    first_name: "Laye",
    last_name: "Thiam"
  )]
end

puts "Creating offers..."
offers_data = [
  {
    title: "Développeur Ruby on Rails",
    url: "https://www.hellowork.com/fr-fr/emplois/1.html",
    description: "Nous recherchons un développeur Ruby on Rails passionné pour rejoindre notre équipe produit. Vous travaillerez sur une plateforme SaaS utilisée par des milliers d'entreprises.",
    city: "Paris",
    domain: "Développement Web",
    salary: 45000,
    job_type: "CDI",
    experience_level: "Junior"
  },
  {
    title: "Développeur Full Stack React / Node.js",
    url: "https://www.hellowork.com/fr-fr/emplois/2.html",
    description: "Rejoignez une startup en forte croissance. Stack technique : React, Node.js, PostgreSQL, AWS. Méthodologie agile, CI/CD, code review systématique.",
    city: "Lyon",
    domain: "Développement Web",
    salary: 50000,
    job_type: "CDI",
    experience_level: "Intermédiaire"
  },
  {
    title: "Data Scientist - NLP",
    url: "https://www.hellowork.com/fr-fr/emplois/3.html",
    description: "Mission : développer des modèles NLP pour l'analyse de documents juridiques. Python, TensorFlow, Hugging Face. Équipe data de 8 personnes.",
    city: "Paris",
    domain: "Data / IA",
    salary: 55000,
    job_type: "CDI",
    experience_level: "Senior"
  }
]

created_offers = offers_data.map { |attrs| Offer.create!(attrs) }

puts "Creating chats with messages..."

chat_templates = [
  {
    title: "Entretien Ruby on Rails",
    offer_index: 0,
    created_at: 2.days.ago,
    messages: [
      { role: "assistant", content: "Bonjour et bienvenue dans cette simulation d'entretien pour le poste de Développeur Ruby on Rails. Je vais vous poser une série de questions techniques et comportementales. Êtes-vous prêt ?" },
      { role: "user", content: "Oui, je suis prêt. Allons-y !" },
      { role: "assistant", content: "Parfait. Commençons par une question technique : pouvez-vous m'expliquer la différence entre `has_many :through` et `has_and_belongs_to_many` dans Rails ? Dans quel cas utiliseriez-vous l'un plutôt que l'autre ?" },
      { role: "user", content: "has_many :through utilise un modèle intermédiaire (join model) ce qui permet d'ajouter des attributs sur la relation, comme une date ou un rôle. has_and_belongs_to_many est plus simple mais ne permet pas d'avoir de logique sur la table de jointure. En pratique, je préfère toujours has_many :through car c'est plus flexible." },
      { role: "assistant", content: "Excellente réponse, c'est exactement ça. La flexibilité du join model est un avantage majeur. Question suivante : comment gérez-vous les N+1 queries dans une application Rails ?" },
      { role: "user", content: "J'utilise `includes` ou `eager_load` pour le eager loading. Par exemple, si j'affiche une liste d'articles avec leurs auteurs, je fais Article.includes(:author) pour éviter une requête par article. J'utilise aussi la gem Bullet en développement pour détecter les N+1 automatiquement." },
      { role: "assistant", content: "Très bien ! L'utilisation de Bullet est un excellent réflexe. Passons à une question comportementale : racontez-moi une situation où vous avez dû résoudre un bug critique en production. Comment avez-vous géré la pression ?" },
      { role: "user", content: "Lors de mon stage, on a eu un bug en prod où les paiements étaient dupliqués. J'ai d'abord regardé les logs pour identifier le problème — c'était un double submit du formulaire. J'ai appliqué un hotfix avec un token d'idempotence côté serveur, puis j'ai communiqué avec l'équipe et les clients affectés. Ensuite j'ai ajouté des tests pour éviter la régression." },
      { role: "assistant", content: "Excellente gestion de crise. Vous avez montré de la méthode : diagnostic, correction rapide, communication et prévention. Dernière question : pourquoi souhaitez-vous rejoindre notre entreprise ?" },
      { role: "user", content: "J'aime l'idée de travailler sur un produit SaaS B2B avec une vraie base d'utilisateurs. Je veux progresser techniquement sur Rails et contribuer à un produit qui a de l'impact. L'environnement startup avec du code review et du CI/CD me correspond parfaitement." },
      { role: "assistant", content: "Merci pour cet entretien ! Voici mon évaluation :\n\n🎯 **Score global : 8.5/10**\n\n✅ **Points forts :**\n- Solides connaissances techniques Rails\n- Bonne capacité à expliquer des concepts complexes\n- Expérience concrète de résolution de problèmes\n- Motivation claire et alignée avec le poste\n\n📈 **Axes d'amélioration :**\n- Approfondir les connaissances en architecture (microservices, event-driven)\n- Préparer des exemples plus détaillés de projets personnels\n\nBonne continuation dans votre recherche !" }
    ]
  },
  {
    title: "Entretien Full Stack React/Node",
    offer_index: 1,
    created_at: 1.day.ago,
    messages: [
      { role: "assistant", content: "Bienvenue dans cette simulation d'entretien pour le poste de Développeur Full Stack React / Node.js. Je suis votre recruteur technique. Commençons !" },
      { role: "user", content: "Merci, je suis motivé pour ce poste !" },
      { role: "assistant", content: "Première question : pouvez-vous m'expliquer le concept de Virtual DOM dans React et pourquoi c'est important pour les performances ?" },
      { role: "user", content: "Le Virtual DOM est une représentation en mémoire du DOM réel. Quand l'état d'un composant change, React crée un nouveau Virtual DOM, le compare avec l'ancien (diffing), et applique uniquement les modifications nécessaires au DOM réel (reconciliation). Ça évite de re-render tout le DOM à chaque changement, ce qui serait très lent." },
      { role: "assistant", content: "Parfait ! Vous maîtrisez bien le sujet. Maintenant côté backend : comment structureriez-vous une API REST avec Node.js/Express pour gérer l'authentification ?" },
      { role: "user", content: "J'utiliserais JWT avec un access token de courte durée et un refresh token. Le flow serait : POST /auth/login renvoie les deux tokens, le access token est envoyé dans le header Authorization, et quand il expire, POST /auth/refresh utilise le refresh token pour en obtenir un nouveau. Je stockerais le refresh token en httpOnly cookie pour la sécurité." }
    ]
  },
  {
    title: "Entretien Data Scientist NLP",
    offer_index: 2,
    created_at: 5.hours.ago,
    messages: [
      { role: "assistant", content: "Bonjour ! Nous allons simuler un entretien pour le poste de Data Scientist spécialisé NLP. Je vais évaluer vos compétences techniques en traitement du langage naturel, machine learning, et votre capacité à résoudre des problèmes concrets. On y va ?" },
      { role: "user", content: "Bonjour, oui je suis prêt !" },
      { role: "assistant", content: "Pour commencer : pouvez-vous m'expliquer la différence entre un modèle BERT et un modèle GPT en termes d'architecture et de cas d'usage ?" }
    ]
  }
]

users.each do |user|
  chat_templates.each do |tmpl|
    chat = Chat.create!(
      user: user,
      offer: created_offers[tmpl[:offer_index]],
      title: tmpl[:title],
      created_at: tmpl[:created_at]
    )
    tmpl[:messages].each { |msg| chat.messages.create!(msg) }
  end
end


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

puts "Seeds done! #{User.count} users, #{Offer.count} offers, #{Chat.count} chats, #{Message.count} messages."

