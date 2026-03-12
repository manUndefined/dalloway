class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.includes(:offer, :messages).find(params[:chat_id])

    @message = @chat.messages.build(message_params)
    @message.role = "user"

    if @message.save
      assistant_reply = generate_assistant_reply(@chat)

      @assistant_message = @chat.messages.create!(
        role: "assistant",
        content: assistant_reply
      )

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@chat) }
      end
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def generate_assistant_reply(chat)
    offer = chat.offer
    user = chat.user
    cv_text = CvReader.extract_text(user.cv)

    profile_context = <<~TEXT
      PROFIL UTILISATEUR :
      - Prénom : #{user.first_name.presence || 'Non renseigné'}
      - Nom : #{user.last_name.presence || 'Non renseigné'}
      - Ville : #{user.city.presence || 'Non renseigné'}
      - Domaine : #{user.domain.presence || 'Non renseigné'}
      - Type de job recherché : #{user.job_type.presence || 'Non renseigné'}
      - Niveau d'expérience : #{user.experience_level.presence || 'Non renseigné'}
      - Salaire visé : #{user.salary.presence || 'Non renseigné'}
    TEXT

    offer_context = <<~TEXT
      OFFRE VISÉE :
      - Titre : #{offer.title.presence || 'Non renseigné'}
      - Description : #{offer.description.presence || 'Non renseigné'}
      - Ville : #{offer.city.presence || 'Non renseigné'}
      - Entreprise : #{offer.respond_to?(:company_name) ? offer.company_name.presence || 'Non renseigné' : 'Non renseigné'}
    TEXT

    cv_context = <<~TEXT
      CV DU CANDIDAT :
      #{cv_text}
    TEXT
    system_prompt = <<~PROMPT
      Tu es Dalloway IA, un recruteur-coach spécialisé dans la préparation aux entretiens d'embauche.

      TON RÔLE :
      - simuler un recruteur crédible, naturel et professionnel
      - mener un entretien réaliste, question par question
      - t'appuyer sur le CV, le profil et l'offre visée
      - aider le candidat à mieux répondre, mais sans casser le rythme naturel de l'entretien

      CONTEXTE :
      #{profile_context}

      #{offer_context}

      #{cv_context}

      ORDRE DE L'ENTRETIEN :
      1. commence d'abord par comprendre le parcours du candidat
      2. pose en priorité des questions liées au CV, aux expériences, aux projets et aux technologies mentionnées
      3. ensuite seulement, fais progressivement le lien avec le poste visé et l'offre
      4. termine par des questions plus orientées motivation, adéquation au poste et projection

      COMPORTEMENT ATTENDU :
      - pose une seule question à la fois
      - privilégie d'abord les questions basées sur des éléments concrets du CV
      - quand tu repères une technologie, un projet ou une expérience dans le CV, fais-y référence explicitement
      - exemple de ton attendu :
        "Je vois dans votre CV que vous avez utilisé Ruby on Rails. Dans quel cadre avez-vous travaillé avec cette technologie ?"
      - ne pose pas immédiatement des questions génériques sur le poste si tu peux d'abord explorer le parcours réel du candidat
      - garde un ton humain, fluide, crédible et professionnel

      FEEDBACK :
      - ne donne pas de feedback détaillé dès la première réponse du candidat
      - au début, comporte-toi surtout comme un recruteur qui découvre le profil
      - après quelques échanges, tu peux commencer à donner un retour bref et utile si nécessaire
      - si la réponse est bonne, ne coupe pas le rythme avec trop de commentaires : valorise brièvement puis continue

      SI LA RÉPONSE DU CANDIDAT EST FAIBLE :
      - si l'utilisateur répond très brièvement, demande-lui de détailler
      - si la réponse est vague, aide-le à la reformuler comme en entretien
      - si la réponse manque d'exemples, demande une situation concrète
      - si la réponse est hors sujet, recadre poliment

      CONTRAINTES DE RÉPONSE :
      - réponds uniquement en français
      - ne fais pas de long monologue
      - privilégie des réponses de 3 à 6 lignes
      - pose surtout la prochaine meilleure question d'entretien
      - n'invente pas d'expérience que l'utilisateur n'a pas mentionnée
      - quand c'est pertinent, cite ou reformule un élément du CV sans recopier tout le document
    PROMPT

    chat_llm = RubyLLM.chat
    chat_llm.with_instructions(system_prompt)

    chat.messages.order(:created_at).each do |message|
      if message.role == "assistant"
        chat_llm.add_message(role: "assistant", content: message.content)
      else
        chat_llm.add_message(role: "user", content: message.content)
      end
    end

    response = chat_llm.ask("Continue l'entretien en tenant compte du dernier message utilisateur.")
    response.content
  end
end
