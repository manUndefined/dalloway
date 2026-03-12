class CoverLettersController < ApplicationController

  def create
    chat = RubyLLM.chat
    response = chat.ask("What is Ruby on Rails?")
    content = response.content

    @cover_letter= CoverLetter.new(cover_letter_params)

    @cover_letter.user = current_user

    @offer = Offer.find(params[:offer_id])

    @cover_letter.offer = @offer

    @cover_letter.save

    redirect_to offer_path(@offer)

  end 

  def update
    @cover_letter = CoverLetter.find(params[:id])
    @cover_letter.update(cover_letter_params)

    redirect_to offer_path(@cover_letter.offer)

  end


  private

  def cover_letter_params
    params.require(:cover_letter).permit(:content, :details)
  end

end
