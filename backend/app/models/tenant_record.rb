# frozen_string_literal: true

class TenantRecord < ApplicationRecord
  self.abstract_class = true

  acts_as_tenant :school
end
