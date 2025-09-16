# frozen_string_literal: true

require 'dry/cli'
require 'json'

module Worktrees
  module Commands
    class List < Dry::CLI::Command
      desc 'List all worktrees for current repository'

      option :format, type: :string, default: 'text', values: %w[text json csv], desc: 'Output format'
      option :status_only, type: :boolean, default: false, desc: 'Show only status information'
      option :filter, type: :string, desc: 'Filter by status (clean, dirty, active)'

      def call(**options)
        begin
          manager = WorktreeManager.new

          # Apply status filter
          status_filter = options[:filter] ? options[:filter].to_sym : nil
          worktrees = manager.list_worktrees(status: status_filter)

          if worktrees.empty?
            puts 'No worktrees found'
            return
          end

          case options[:format]
          when 'json'
            output_json(worktrees)
          when 'csv'
            output_csv(worktrees)
          else
            output_text(worktrees, options[:status_only])
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

      def output_text(worktrees, status_only = false)
        worktrees.each do |worktree|
          marker = worktree.active? ? '*' : ' '

          if status_only
            puts "#{marker} #{worktree.name} #{worktree.status}"
          else
            puts format('%s %-20s %-8s %-40s (from %s)',
                       marker,
                       worktree.name,
                       worktree.status,
                       worktree.path,
                       worktree.base_ref)
          end
        end
      end

      def output_json(worktrees)
        data = {
          worktrees: worktrees.map(&:to_h)
        }
        puts JSON.pretty_generate(data)
      end

      def output_csv(worktrees)
        puts 'name,status,path,branch,base_ref,active'
        worktrees.each do |worktree|
          puts [
            worktree.name,
            worktree.status,
            worktree.path,
            worktree.branch,
            worktree.base_ref,
            worktree.active?
          ].join(',')
        end
      end
    end
  end
end