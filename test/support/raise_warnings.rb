# frozen_string_literal: true

$VERBOSE = true
module RaiseWarnings
  def warn(message, *)
    super
    raise message
  end
  ruby2_keywords :warn if respond_to?(:ruby2_keywords, true)
end
Warning.singleton_class.prepend(RaiseWarnings)
