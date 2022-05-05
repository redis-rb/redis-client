# frozen_string_literal: true

module RaiseWarnings
  def warn(message, *, **)
    super
    raise message
  end
end
Warning.singleton_class.prepend(RaiseWarnings)
