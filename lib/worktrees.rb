# frozen_string_literal: true

require_relative 'worktrees/version'

require_relative 'worktrees/models/feature_worktree'
require_relative 'worktrees/models/repository'
require_relative 'worktrees/models/worktree_config'

require_relative 'worktrees/git_operations'
require_relative 'worktrees/worktree_manager'

require_relative 'worktrees/commands/create'
require_relative 'worktrees/commands/list'
require_relative 'worktrees/commands/switch'
require_relative 'worktrees/commands/remove'
require_relative 'worktrees/commands/status'

require_relative 'worktrees/cli'

module Worktrees
  class Error < StandardError; end
  class ValidationError < Error; end
  class GitError < Error; end
  class StateError < Error; end
  class FileSystemError < Error; end
  class NotFoundError < Error; end
end