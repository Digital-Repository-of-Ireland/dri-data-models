Rails.application.routes.draw do

  mount DriDataModels::Engine => "/dri_data_models"
end
