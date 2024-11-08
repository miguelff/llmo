json.extract! report, :id, :status, :created_at, :updated_at
json.url report_url(report, format: :json)
