class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.includes(:offer, :messages).find(params[:chat_id])

    @message = @chat.messages.build(message_params)
    @message.role = "user"

    if @message.save
      assistant_reply = handle_interview_flow(@chat)

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

  def handle_interview_flow(chat)
    last_user_message = chat.messages.where(role: "user").order(:created_at).last&.content.to_s.strip.downcase
    last_assistant_message = chat.messages.where(role: "assistant").order(:created_at).last&.content.to_s

    if continuation_prompt?(last_assistant_message)
      return generate_final_feedback(chat) if negative_answer?(last_user_message)
      return generate_assistant_reply(chat) if positive_answer?(last_user_message)

      return "Merci de répondre simplement par oui ou non : souhaitez-vous continuer l’entretien ?"
    end

    return generate_mid_interview_feedback(chat) if should_offer_mid_interview_feedback?(chat)

    generate_assistant_reply(chat)
  end

  def should_offer_mid_interview_feedback?(chat)
    user_messages_count = chat.messages.where(role: "user").count
    last_assistant_message = chat.messages.where(role: "assistant").order(:created_at).last&.content.to_s

    user_messages_count.positive? &&
      (user_messages_count % 3).zero? &&
      !continuation_prompt?(last_assistant_message)
  end

  def continuation_prompt?(message)
    message.downcase.include?("souhaitez-vous continuer")
  end

  def positive_answer?(message)
    message.match?(/\A(oui|oui\.|oui!|oui !)\z/i)
  end

  def negative_answer?(message)
    message.match?(/\A(non|non\.|non!|non !)\z/i)
  end

  def generate_mid_interview_feedback(chat)
    user_messages = chat.messages
                        .where(role: "user")
                        .order(:created_at)
                        .last(3)
                        .map(&:content)
                        .join("\n\n")

    feedback_prompt = <<~PROMPT
      Tu es Dalloway IA, un coach d'entretien honnête, professionnel et utile.

      Tu dois produire un mini feedback intermédiaire basé uniquement sur les 3 dernières réponses du candidat.

      CONSIGNES IMPORTANTES :
      - sois honnête
      - n'invente rien
      - si les réponses sont trop courtes, trop vagues ou peu exploitables, dis-le clairement
      - si les réponses sont bonnes, dis-le aussi honnêtement
      - donne un retour bref, utile et crédible
      - réponds uniquement en français
      - reste concis : 3 à 5 lignes maximum
      - termine obligatoirement par cette phrase exacte :
        "Souhaitez-vous continuer l’entretien ? (oui/non)"

      RÉPONSES DU CANDIDAT :
      #{user_messages}
    PROMPT

    chat_llm = RubyLLM.chat
    chat_llm.with_instructions(feedback_prompt)

    response = chat_llm.ask("Fais maintenant un mini feedback intermédiaire honnête sur ces réponses.")
    response.content
  end

  def generate_assistant_reply(chat)
    system_prompt = interview_system_prompt(chat)

    chat_llm = RubyLLM.chat
    chat_llm.with_instructions(system_prompt)

    add_chat_history(chat_llm, chat)

    response = chat_llm.ask("Continue l'entretien en tenant compte du dernier message utilisateur.")
    response.content
  end

  def generate_final_feedback(chat)
    user = chat.user
    offer = chat.offer
    cv_text = CvReader.extract_text(user.cv)

    feedback_prompt = <<~PROMPT
      Tu es Dalloway IA, un coach en préparation d'entretien.

      Tu dois maintenant produire un bilan final de l'entretien à partir :
      - du profil utilisateur
      - de l'offre visée
      - du CV
      - de l'historique complet de l'échange

      CONTEXTE UTILISATEUR :
      - Prénom : #{user.first_name.presence || 'Non renseigné'}
      - Nom : #{user.last_name.presence || 'Non renseigné'}
      - Ville : #{user.city.presence || 'Non renseigné'}
      - Domaine : #{user.domain.presence || 'Non renseigné'}
      - Type de job recherché : #{user.job_type.presence || 'Non renseigné'}
      - Niveau d'expérience : #{user.experience_level.presence || 'Non renseigné'}
      - Salaire visé : #{user.salary.presence || 'Non renseigné'}

      OFFRE VISÉE :
      - Titre : #{offer.title.presence || 'Non renseigné'}
      - Description : #{offer.description.presence || 'Non renseigné'}
      - Ville : #{offer.city.presence || 'Non renseigné'}
      - Entreprise : #{offer.respond_to?(:company_name) ? offer.company_name.presence || 'Non renseigné' : 'Non renseigné'}

      CV DU CANDIDAT :
      #{cv_text}

      CONSIGNE DE RÉPONSE :
      - réponds uniquement en français
      - adopte un ton professionnel, bienveillant et utile
      - fais un vrai bilan final de l'entretien
      - donne un score global sur 10
      - structure impérativement la réponse comme ceci :

      Merci pour cet entraînement.

      Score global : X/10

      Points forts :
      - ...
      - ...

      Axes d'amélioration :
      - ...
      - ...

      Conseil prioritaire pour le prochain entretien :
      ...

      - base-toi sur ce que le candidat a réellement dit
      - n'invente pas d'expérience
      - reste concret et concis
    PROMPT

    chat_llm = RubyLLM.chat
    chat_llm.with_instructions(feedback_prompt)

    add_chat_history(chat_llm, chat)

    response = chat_llm.ask("Fais maintenant le bilan final complet de cet entretien.")
    response.content
  end

  def interview_system_prompt(chat)
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

    <<~PROMPT
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
  end

  def add_chat_history(chat_llm, chat)
    chat.messages.order(:created_at).each do |message|
      if message.role == "assistant"
        chat_llm.add_message(role: "assistant", content: message.content)
      else
        chat_llm.add_message(role: "user", content: message.content)
      end
    end
  end
end
