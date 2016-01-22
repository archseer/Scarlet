require 'scarlet/helpers/message_helper'

class Scarlet
  # Included in all Scarlet plugins.
  module BaseHelper
    include MessageHelper

    def params
      event.params
    end

    def config
      event.server.config
    end

    def sender
      event.sender
    end

    def server
      event.server
    end
  end
end
