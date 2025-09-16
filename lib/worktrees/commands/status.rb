# frozen_string_literal: true

require 'dry/cli'
require 'json'

module Worktrees
  module Commands
    class Status < Dry::CLI::Command
      desc 'Show current worktree status'

      option :format, type: :string, default: 'text', values: %w[text json], desc: 'Output format'

      def call(**options)
        begin
          manager = WorktreeManager.new
          current_worktree = manager.current_worktree

          if current_worktree.nil?
            warn 'ERROR: Not in a worktree'
            show_repository_info(manager, options[:format])
            exit(4)
          end

          case options[:format]
          when 'json'
            output_json(current_worktree, manager)
          else
            output_text(current_worktree, manager)
          end

        rescue GitError => e
          warn "ERROR: Git: #{e.message}"
          exit(3)
        rescue StandardError => e
          warn "ERROR: #{e.message}"
          exit(1)
        end
      end

      private

      def output_text(worktree, manager)
        puts "Current worktree: #{worktree.name}"
        puts "  Path: #{worktree.path}"
        puts "  Branch: #{worktree.branch}"
        puts "  Base: #{worktree.base_ref}"

        # Show detailed status
        case worktree.status
        when :dirty
          # Could enhance to show number of modified files
          puts "  Status: dirty (modified files)"
        else
          puts "  Status: #{worktree.status}"
        end

        puts ''
        show_repository_info(manager, 'text')
      end

      def output_json(worktree, manager)
        data = {
          current_worktree: worktree.to_h,
          repository: {
            root_path: manager.repository.root_path,
            worktrees_root: manager.config.expand_worktrees_root,
            default_branch: manager.repository.default_branch,
            remote_url: manager.repository.remote_url
          }
        }
        puts JSON.pretty_generate(data)
      end

      def show_repository_info(manager, format)
        if format == 'json'
          data = {
            repository: {
              root_path: manager.repository.root_path,
              worktrees_root: manager.config.expand_worktrees_root,
              default_branch: manager.repository.default_branch,
              remote_url: manager.repository.remote_url
            }
          }
          puts JSON.pretty_generate(data)
        else
          puts "Repository: #{manager.repository.root_path}"
          puts "Worktrees root: #{manager.config.expand_worktrees_root}"
          if manager.repository.remote_url
            puts "Remote: #{manager.repository.remote_url}"
          end
        end
      end
    end
  end
end