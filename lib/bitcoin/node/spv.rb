module Bitcoin
  module Node

    # SPV module
    module SPV

      autoload :CLI, 'bitcoin/node/spv/cli'
      autoload :Daemon, 'bitcoin/node/spv/daemon'

    end

  end
end