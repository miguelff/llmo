module ChartsHelper
    def chart(options = {})
        ApplicationController.render partial: "/charts/chart", locals: { options: options, id: SecureRandom.hex }
    end
end
