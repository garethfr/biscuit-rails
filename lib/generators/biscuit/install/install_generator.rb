require "rails/generators"

module Biscuit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs the biscuit-rails Claude Code setup skill into .claude/skills/biscuit-install/"

      def copy_claude_skill
        empty_directory ".claude/skills/biscuit-install"
        copy_file "SKILL.md", ".claude/skills/biscuit-install/SKILL.md"

        say ""
        say "  Claude Code skill installed at .claude/skills/biscuit-install/SKILL.md", :green
        say ""
        say "  Open Claude Code in this project and run:", :cyan
        say "    /biscuit-install", :cyan
        say ""
        say "  The skill will check compatibility, configure the gem, audit your existing", :cyan
        say "  cookies and tracking scripts, add tests, and optionally commit.", :cyan
        say ""
      end
    end
  end
end
