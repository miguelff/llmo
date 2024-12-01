class String
    def promptize
        self.gsub(/^\s+/, "").freeze
    end
end
