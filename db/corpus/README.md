# Demo corpus: Rails Guides

The `*.yml` files in this directory are the documents indexed by the full-text
search demo: the English [Ruby on Rails Guides](https://guides.rubyonrails.org/)
for the Rails version the app runs, split into sections. They are generated
from the Markdown under `guides/source/` in the
[rails/rails](https://github.com/rails/rails) repository by
`bin/rails corpus:fetch` and `RailsGuides::SectionSplitter`
(`lib/rails_guides/section_splitter.rb`).

The guides are © the Rails contributors and are licensed under
[Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/).
Every file records the page it was taken from (`url`) and the source file and
git ref it was built from (`source`, `ref`), and every section carries the
anchor of its heading, so the demo can link back to the original text.

## File format

One file per guide, named after the slug of the guide's URL, with the keys
`slug`, `title`, `description`, `url`, `source`, `ref` and `sections`. Each
section has `anchor` (the id of the heading on guides.rubyonrails.org),
`title`, `parent` (the H2 title for an H3 section, empty for an H2 section) and
`body`, a literal block of plain text.

## How the split works

A guide becomes one document per H2 heading (holding the text before its first
H3) and one per H3 heading, with `####` and deeper headings folded into the
enclosing document as a line of text; headings with no text of their own are
skipped. Bodies are plain text: fenced code, images, HTML tags, link targets,
emphasis markers, table pipes and `NOTE:`-style labels are removed, wrapped
lines are joined and paragraphs are separated by a single blank line.

## Regenerating

```sh
bin/rails corpus:fetch
```

The task reads `guides/source/documents.yaml` at the tag matching the app's
Rails version, falling back to the newest tag of the same minor series (that
lookup goes through api.github.com; set `GITHUB_TOKEN` if it is rate limited),
downloads every guide that is not marked work in progress, splits it and
rewrites the files here, deleting the files of guides that are no longer
listed. The per-version release notes are left out on purpose: those pages are
long changelogs rather than prose and would dominate the index. Set `GUIDES_REF`
to build from another tag or branch. The output is deterministic, so a second
run reports no changes. The table below is kept up to date by the task.

## Guides

<!-- corpus:fetch start -->
Source: [rails/rails at `v8.1.4`](https://github.com/rails/rails/tree/v8.1.4/guides/source), fetched by `bin/rails corpus:fetch`.

| Guide | File | Sections |
| --- | --- | ---: |
| [Getting Started with Rails](https://guides.rubyonrails.org/v8.1/getting_started.html) | `getting_started` | 63 |
| [Install Ruby on Rails Guide](https://guides.rubyonrails.org/v8.1/install_ruby_on_rails.html) | `install_ruby_on_rails` | 6 |
| [Active Record Basics](https://guides.rubyonrails.org/v8.1/active_record_basics.html) | `active_record_basics` | 19 |
| [Active Record Migrations](https://guides.rubyonrails.org/v8.1/active_record_migrations.html) | `active_record_migrations` | 42 |
| [Active Record Validations](https://guides.rubyonrails.org/v8.1/active_record_validations.html) | `active_record_validations` | 47 |
| [Active Record Callbacks](https://guides.rubyonrails.org/v8.1/active_record_callbacks.html) | `active_record_callbacks` | 26 |
| [Active Record Associations](https://guides.rubyonrails.org/v8.1/association_basics.html) | `association_basics` | 43 |
| [Active Record Query Interface](https://guides.rubyonrails.org/v8.1/active_record_querying.html) | `active_record_querying` | 75 |
| [Active Model Basics](https://guides.rubyonrails.org/v8.1/active_model_basics.html) | `active_model_basics` | 15 |
| [Action View Overview](https://guides.rubyonrails.org/v8.1/action_view_overview.html) | `action_view_overview` | 24 |
| [Layouts and Rendering in Rails](https://guides.rubyonrails.org/v8.1/layouts_and_rendering.html) | `layouts_and_rendering` | 12 |
| [Action View Helpers](https://guides.rubyonrails.org/v8.1/action_view_helpers.html) | `action_view_helpers` | 38 |
| [Action View Form Helpers](https://guides.rubyonrails.org/v8.1/form_helpers.html) | `form_helpers` | 34 |
| [Action Controller Overview](https://guides.rubyonrails.org/v8.1/action_controller_overview.html) | `action_controller_overview` | 27 |
| [Action Controller Advanced Topics](https://guides.rubyonrails.org/v8.1/action_controller_advanced_topics.html) | `action_controller_advanced_topics` | 20 |
| [Rails Routing from the Outside In](https://guides.rubyonrails.org/v8.1/routing.html) | `routing` | 56 |
| [Active Support Core Extensions](https://guides.rubyonrails.org/v8.1/active_support_core_extensions.html) | `active_support_core_extensions` | 81 |
| [Action Mailer Basics](https://guides.rubyonrails.org/v8.1/action_mailer_basics.html) | `action_mailer_basics` | 35 |
| [Action Mailbox Basics](https://guides.rubyonrails.org/v8.1/action_mailbox_basics.html) | `action_mailbox_basics` | 18 |
| [Action Text Overview](https://guides.rubyonrails.org/v8.1/action_text_overview.html) | `action_text_overview` | 16 |
| [Active Job Basics](https://guides.rubyonrails.org/v8.1/active_job_basics.html) | `active_job_basics` | 26 |
| [Active Storage Overview](https://guides.rubyonrails.org/v8.1/active_storage_overview.html) | `active_storage_overview` | 41 |
| [Action Cable Overview](https://guides.rubyonrails.org/v8.1/action_cable_overview.html) | `action_cable_overview` | 34 |
| [Testing Rails Applications](https://guides.rubyonrails.org/v8.1/testing.html) | `testing` | 63 |
| [Debugging Rails Applications](https://guides.rubyonrails.org/v8.1/debugging_rails_applications.html) | `debugging_rails_applications` | 27 |
| [Configuring Rails Applications](https://guides.rubyonrails.org/v8.1/configuring.html) | `configuring` | 38 |
| [The Rails Command Line](https://guides.rubyonrails.org/v8.1/command_line.html) | `command_line` | 33 |
| [The Asset Pipeline](https://guides.rubyonrails.org/v8.1/asset_pipeline.html) | `asset_pipeline` | 17 |
| [Working with JavaScript in Rails](https://guides.rubyonrails.org/v8.1/working_with_javascript_in_rails.html) | `working_with_javascript_in_rails` | 14 |
| [Internationalization (I18n)](https://guides.rubyonrails.org/v8.1/i18n.html) | `i18n` | 34 |
| [Autoloading and Reloading Constants](https://guides.rubyonrails.org/v8.1/autoloading_and_reloading_constants.html) | `autoloading_and_reloading_constants` | 26 |
| [Using Rails for API-only Applications](https://guides.rubyonrails.org/v8.1/api_app.html) | `api_app` | 15 |
| [Tuning Performance for Deployment](https://guides.rubyonrails.org/v8.1/tuning_performance_for_deployment.html) | `tuning_performance_for_deployment` | 15 |
| [Caching with Rails](https://guides.rubyonrails.org/v8.1/caching_with_rails.html) | `caching_with_rails` | 26 |
| [Securing Rails Applications](https://guides.rubyonrails.org/v8.1/security.html) | `security` | 50 |
| [Error Reporting in Rails Applications](https://guides.rubyonrails.org/v8.1/error_reporting.html) | `error_reporting` | 8 |
| [Multiple Databases with Active Record](https://guides.rubyonrails.org/v8.1/active_record_multiple_databases.html) | `active_record_multiple_databases` | 11 |
| [Active Record Encryption](https://guides.rubyonrails.org/v8.1/active_record_encryption.html) | `active_record_encryption` | 30 |
| [Composite Primary Keys](https://guides.rubyonrails.org/v8.1/active_record_composite_primary_keys.html) | `active_record_composite_primary_keys` | 8 |
| [The Basics of Creating Rails Plugins](https://guides.rubyonrails.org/v8.1/plugins.html) | `plugins` | 20 |
| [Rails on Rack](https://guides.rubyonrails.org/v8.1/rails_on_rack.html) | `rails_on_rack` | 17 |
| [Rails Generators & Templates](https://guides.rubyonrails.org/v8.1/generators.html) | `generators` | 27 |
| [Contributing to Ruby on Rails](https://guides.rubyonrails.org/v8.1/contributing_to_ruby_on_rails.html) | `contributing_to_ruby_on_rails` | 31 |
| [API Documentation Guidelines](https://guides.rubyonrails.org/v8.1/api_documentation_guidelines.html) | `api_documentation_guidelines` | 19 |
| [Ruby on Rails Guides Guidelines](https://guides.rubyonrails.org/v8.1/ruby_on_rails_guides_guidelines.html) | `ruby_on_rails_guides_guidelines` | 15 |
| [Installing Rails Core Development Dependencies](https://guides.rubyonrails.org/v8.1/development_dependencies_install.html) | `development_dependencies_install` | 9 |
| [Maintenance Policy for Ruby on Rails](https://guides.rubyonrails.org/v8.1/maintenance_policy.html) | `maintenance_policy` | 7 |
| [Upgrading Ruby on Rails](https://guides.rubyonrails.org/v8.1/upgrading_ruby_on_rails.html) | `upgrading_ruby_on_rails` | 147 |

48 guides, 1,505 sections in total.
<!-- corpus:fetch end -->
