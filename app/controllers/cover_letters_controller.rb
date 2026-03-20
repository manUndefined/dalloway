class CoverLettersController < ApplicationController
  def create
    @offer = Offer.find(params[:offer_id])

    @cover_letter = CoverLetter.create!(
      user: current_user,
      offer: @offer,
      details: params[:cover_letter][:details]
    )

    GenerateCoverLetterJob.perform_later(@cover_letter)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to offer_path(@offer) }
    end
  end

  def update
    @cover_letter = current_user.cover_letters.find(params[:id])
    @offer = @cover_letter.offer

    @cover_letter.update!(cover_letter_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to offer_path(@offer) }
    end
  end

  def regenerate
    @cover_letter = current_user.cover_letters.find(params[:id])
    @offer = @cover_letter.offer

    @cover_letter.update!(content: nil, details: params.dig(:cover_letter, :details) || @cover_letter.details)
    GenerateCoverLetterJob.perform_later(@cover_letter)

    respond_to do |format|
      format.turbo_stream { render "cover_letters/create" }
      format.html { redirect_to offer_path(@offer) }
    end
  end

  private

  def cover_letter_params
    params.require(:cover_letter).permit(:content, :details)
  end
end
