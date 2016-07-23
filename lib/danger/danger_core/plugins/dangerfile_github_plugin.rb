require "danger/plugin_support/plugin"

module Danger
  # Handles interacting with GitHub inside a Dangerfile. Provides a few functions which wrap `pr_json` and also
  # through a few standard functions to simplify your code.
  #
  # @example Warn when a PR is classed as work in progress
  #
  #          warn "PR is classed as Work in Progress" if github.pr_title.include? "[WIP]"
  #
  # @example Ensure that labels have been used on the PR
  #
  #          fail "Please add labels to this PR" if github.labels.empty?
  #
  # @example Check if a user is in a specific GitHub org, and message them if so
  #
  #          unless github.api.organization_member?('danger', github.pr_author)
  #            message "@#{pr_author} is not a contributor yet, would you like to join the Danger org?"
  #          end
  #
  # @example Ensure there is a summary for a PR
  #
  #          fail "Please provide a summary in the Pull Request description" if github.pr_body.length < 5
  #
  # @see  danger/danger
  # @tags core, github

  class DangerfileGitHubPlugin < Plugin
    def initialize(dangerfile)
      super(dangerfile)
      return nil unless dangerfile.env.request_source.class == Danger::RequestSources::GitHub

      @github = dangerfile.env.request_source
    end

    # The instance name used in the Dangerfile
    # @return [String]
    #
    def self.instance_name
      "github"
    end

    # @!group PR Metadata
    # The title of the Pull Request.
    # @return [String]
    #
    def pr_title
      @github.pr_json[:title].to_s
    end

    # @!group PR Metadata
    # The body text of the Pull Request.
    # @return [String]
    #
    def pr_body
      pr_json[:body].to_s
    end

    # @!group PR Metadata
    # The username of the author of the Pull Request.
    # @return [String]
    #
    def pr_author
      pr_json[:user][:login].to_s
    end

    # @!group PR Metadata
    # The labels assigned to the Pull Request.
    # @return [String]
    #
    def pr_labels
      @github.issue_json[:labels].map { |l| l[:name] }
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged into.
    # @return [String]
    #
    def branch_for_base
      pr_json[:base][:ref]
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged from.
    # @return [String]
    #
    def branch_for_head
      pr_json[:head][:ref]
    end

    # @!group PR Commit Metadata
    # The base commit to which the PR is going to be merged as a parent.
    # @return [String]
    #
    def base_commit
      pr_json[:base][:sha]
    end

    # @!group PR Commit Metadata
    # The head commit to which the PR is requesting to be merged from.
    # @return [String]
    #
    def head_commit
      pr_json[:head][:sha]
    end

    # @!group GitHub Misc
    # The hash that represents the PR's JSON. For an example of what this looks like
    # see the [Danger Fixture'd one](https://raw.githubusercontent.com/danger/danger/master/spec/fixtures/pr_response.json).
    # @return [Hash]
    #
    def pr_json
      @github.pr_json
    end

    # @!group GitHub Misc
    # Provides access to the GitHub API client used inside Danger. Making
    # it easy to use the GitHub API inside a Dangerfile.
    # @return [Octokit::Client]
    def api
      @github.client
    end

    # @!group PR Content
    # The unified diff produced by Github for this PR
    # see [Unified diff](https://en.wikipedia.org/wiki/Diff_utility#Unified_format)
    # @return [String]
    def pr_diff
      @github.pr_diff
    end

    # @!group GitHub Misc
    # Returns an HTML link for a file in the head repository. An example would be
    # `<a href='https://github.com/artsy/eigen/blob/561827e46167077b5e53515b4b7349b8ae04610b/file.txt'>file.txt</a>`
    # @return String
    def html_link(paths)
      paths = [paths] unless paths.kind_of?(Array)
      commit = head_commit
      repo = pr_json[:head][:repo][:html_url]
      paths = paths.map do |path|
        path_with_slash = "/#{path}" unless path.start_with? "/"
        create_link("#{repo}/blob/#{commit}#{path_with_slash}", path)
      end

      return paths.first if paths.count < 2
      paths.first(paths.count - 1).join(", ") + " & " + paths.last
    end

    private

    def create_link(href, text)
      "<a href='#{href}'>#{text}</a>"
    end
  end
end
