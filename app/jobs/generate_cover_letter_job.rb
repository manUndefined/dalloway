class GenerateCoverLetterJob < ApplicationJob
  queue_as :default

  attr_reader :user, :offer, :cover_letter, :prompt, :response

  def perform(cover_letter)
    @cover_letter = cover_letter
    @user = cover_letter.user
    @offer = cover_letter.offer

    begin
      write_prompts
      call_llm

      @cover_letter.update!(content: response.content)

      broadcast_response
    rescue StandardError => e
      @cover_letter.update!(
        content: "❌ Une erreur est survenue lors de la génération. Merci de réessayer."
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        "cover_letters_#{user.id}_offer_#{offer.id}",
        target: "cover_letter_box",
        partial: "cover_letters/cover_letter",
        locals: { cover_letter: @cover_letter }
      )
    end
  end

  def write_prompts
    cv_text = CvReader.extract_text(user.cv)

    profile_context = <<~TEXT
      PROFIL DU CANDIDAT :
      - Prénom : #{user.first_name.presence || 'Non renseigné'}
      - Nom : #{user.last_name.presence || 'Non renseigné'}
      - Ville : #{user.city.presence || 'Non renseigné'}
      - Domaine : #{user.domain.presence || 'Non renseigné'}
      - Type de job recherché : #{user.job_type.presence || 'Non renseigné'}
      - Niveau d'expérience : #{user.experience_level.presence || 'Non renseigné'}
    TEXT

    offer_context = <<~TEXT
      OFFRE VISÉE :
      - Titre : #{offer.title.presence || 'Non renseigné'}
      - Description : #{offer.description.presence || 'Non renseigné'}
      - Ville : #{offer.city.presence || 'Non renseigné'}
      - Domaine : #{offer.domain.presence || 'Non renseigné'}
      - Type de contrat : #{offer.job_type.presence || 'Non renseigné'}
      - Niveau d'expérience demandé : #{offer.experience_level.presence || 'Non renseigné'}
    TEXT

    details_context = <<~TEXT
      PRÉCISIONS AJOUTÉES PAR LE CANDIDAT :
      #{cover_letter.details.presence || 'Aucune précision supplémentaire'}
    TEXT

    cv_context = <<~TEXT
      CV DU CANDIDAT :
      #{cv_text}
    TEXT

    @prompt = <<~PROMPT
      Tu es un expert en rédaction de lettres de motivation modernes, crédibles et professionnelles.

      Ta mission est de rédiger une lettre de motivation courte à moyenne, personnalisée et naturelle, à partir :
      - du profil du candidat
      - du CV du candidat
      - de l'offre visée
      - des précisions ajoutées par le candidat

      CONSIGNES IMPORTANTES :
      - rédige uniquement en français
      - fais une vraie lettre de motivation, pas une liste
      - vise une lettre courte à moyenne : environ 200 à 300 mots maximum
      - adopte un ton naturel, moderne, direct et crédible
      - évite le style trop scolaire, trop institutionnel ou trop parfait
      - privilégie des phrases plutôt courtes et percutantes
      - adapte clairement la lettre au poste visé
      - valorise uniquement les expériences, compétences et technologies réellement présentes dans le CV ou les précisions utilisateur
      - n'invente jamais une expérience inexistante
      - n'invente pas d'entreprise précédente, de résultat chiffré ou de mission non mentionnée
      - n'évoque jamais le salaire dans la lettre
      - si le CV est vide, peu lisible ou non exploitable, appuie-toi surtout sur le profil et les précisions du candidat
      - si le candidat manque d'expérience, mets en avant sa motivation, sa capacité d'apprentissage, sa logique de progression
      - montre pourquoi son profil peut être intéressant pour ce poste, même s'il est junior ou en reconversion
      - structure la lettre avec :
        - une accroche courte
        - un paragraphe sur le parcours / les compétences
        - un paragraphe sur l'intérêt pour le poste / l'entreprise
        - une conclusion simple et professionnelle

      - ne mets ni objet, ni adresse postale, ni date

      - la lettre doit ressembler à une vraie lettre de motivation lisible sur une page web
      - fais des paragraphes bien séparés
      - respecte impérativement une fin de lettre propre et aérée
      - termine impérativement avec cette structure exacte :
        - une dernière phrase de conclusion courte
        - une ligne vide
        - "Bien cordialement,"
        - une ligne vide
        - le prénom et le nom du candidat sur une ligne dédiée
        - la ville sur une dernière ligne si elle est connue

      - n’écris pas toute la fin sur une seule ligne
      - ne colle pas la formule de politesse au dernier paragraphe

      CONTEXTE :

      #{profile_context}

      #{offer_context}

      #{details_context}

      #{cv_context}
    PROMPT
  end

  def call_llm
    puts "CALL LLM"
    chat = RubyLLM.chat
    chat.with_instructions(prompt)

    @response = chat.ask("Rédige maintenant la lettre de motivation complète.")
  end

  def broadcast_response
    puts "broadcast_response"
    Turbo::StreamsChannel.broadcast_replace_to(
      "cover_letters_#{user.id}_offer_#{offer.id}",
      target: "cover_letter_box",
      partial: "cover_letters/cover_letter",
      locals: { cover_letter: @cover_letter }
    )
  end
end
