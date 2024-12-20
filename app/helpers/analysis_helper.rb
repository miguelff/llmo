module AnalysisHelper
    STEPS = [ :your_website, :your_brand, :order_confirmation, :pay, :receive_report ]

    def step_classes_for(menu_step, current_step)
      [ "step" ].tap do |classes|
        if STEPS.index(menu_step) <= STEPS.index(current_step)
          classes << "step-primary"
        end
      end.join(" ")
    end
end
