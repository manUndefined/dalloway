class CoverLettersController < ApplicationController
  def create
    @offer = Offer.find(params[:offer_id])

    cover_letter = CoverLetter.create!(
      user: current_user,
      offer: @offer,
      content: "Génération en cours...",
      details: params[:cover_letter][:details]
    )

    GenerateCoverLetterJob.perform_later(cover_letter)

    redirect_to offer_path(@offer)
  end

  def update
    @cover_letter = CoverLetter.find(params[:id])
    @offer = @cover_letter.offer

    @cover_letter.update(cover_letter_params)

    redirect_to offer_path(@offer)
  end

  private

  def cover_letter_params
    params.require(:cover_letter).permit(:content, :details)
  end
end
