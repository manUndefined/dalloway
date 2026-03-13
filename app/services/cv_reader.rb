require "pdf-reader"

class CvReader
  def self.extract_text(cv_attachment)
    return "CV non disponible." unless cv_attachment.attached?

    file = cv_attachment.download
    reader = PDF::Reader.new(StringIO.new(file))

    text = ""

    reader.pages.each do |page|
      text += page.text + "\n"
    end

    text.truncate(4000)
  rescue StandardError
    "Impossible de lire le CV."
  end
end
