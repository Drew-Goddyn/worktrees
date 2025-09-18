# frozen_string_literal: true

require 'dry/cli'
require 'json'

module Worktrees
  module Commands
    # Lists all worktrees with filtering and multiple output formats
    class List < Dry::CLI::Command
      desc 'List all worktrees for current repository'

      option :format, type: :string, default: 'text', values: %w[text json csv], desc: 'Output format'
      option :status_only, desc: 'Show only status information', type: :boolean, default: false
      option :filter, type: :string, desc: 'Filter by status (clean, dirty, active)'

      def call(**options)
        manager = WorktreeManager.new
        worktrees = fetch_worktrees(manager, options)

        return puts 'No worktrees found' if worktrees.empty?

        output_worktrees(worktrees, options)
      rescue GitError => e
        warn "ERROR: Git: #{e.message}"
        exit(3)
      rescue StandardError => e
        warn "ERROR: #{e.message}"
        exit(1)
      end

      private

      def fetch_worktrees(manager, options)
        status_filter = options[:filter]&.to_sym
        manager.list_worktrees(status: status_filter)
      end

      def output_worktrees(worktrees, options)
        case options[:format]
        when 'json'
          output_json(worktrees)
        when 'csv'
          output_csv(worktrees)
        else
          output_text(worktrees, status_only: options[:status_only])
        end
      end

      def output_text(worktrees, status_only: false)
        worktrees.each do |worktree|
          marker = worktree.active? ? '*' : ' '

          if status_only
            puts "#{marker} #{worktree.name} #{worktree.status}"
          else
            puts format('%<marker>s %-<name>20s %-<status>8s %-<path>40s (from %<base>s)',
                        marker: marker,
                        name: worktree.name,
                        status: worktree.status,
                        path: worktree.path,
                        base: worktree.base_ref)
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
        worktrees.each { |worktree| puts build_csv_row(worktree) }
      end

      def build_csv_row(worktree)
        [
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
