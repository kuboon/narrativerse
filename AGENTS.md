# Narrativerse Agent Notes

## Current Status
- Rails 8 app scaffolding complete with SQLite DB.
- Core models and migrations for User, Plot, Scene, Element, ElementRevision, PlotElement, PlotSceneLink, PlotParentLink.
- Minimal UI for home, plots, elements, plot reading, and plot element management.
- Services in place: PlotBuilder, PlotNavigation, PlotForker, ElementRevisionManager, PlotStory.
- Reader is now `ReaderController` with story-flow rendering at `/reader/:plot_id(/:link_id)`.
- Scene CRUD UI removed; scenes are created when writing plot story segments.
- Plot show now renders story flow by stitching linked scenes.
- UI strings are Japanese-first; locale default set to `:ja`.
- Tests added for PlotBuilder, PlotForker, PlotSceneLinksController, ElementRevisionManager.
- PlotSceneLinksController tests stay IntegrationTest-based with Spec DSL for request helpers.

## Recent Commits
- (current) Reader migration and hidden scenes
- d2dfeb5 Avoid nested forms for AI buttons
- 1ad5516 Design marketing landing page
- 4adb7bf Enforce unique plot elements

## How to Run
- Ruby via mise: `/home/vscode/.local/bin/mise exec -- ruby -v`
- Run tests: `/home/vscode/.local/bin/mise exec -- bin/rails test`

## Important Implementation Details
- Reading URL: `/reader/:plot_id(/:link_id)` (legacy `/plots/:plot_id/plot_scene_links/:link_id` points to Reader).
- PlotStory builds a full story-flow by walking links (and parents) and returns focus link + branches.
- PlotBuilder still exists for legacy reading, but reader uses PlotStory.
- PlotSceneLinksController now only handles authoring (new/create/fork), reader is public.
- PlotForker duplicates a plot from a specific scene and links to parent plot (self-fork guard).
- ElementRevisionManager updates owned plot elements to latest revision and prunes unreferenced revisions.
- Locale config: `config.i18n.default_locale = :ja` in `config/application.rb`.

## TODO / Next Steps
1. Reader migration cleanup
   - Remove unused legacy PlotBuilder view if no longer needed.
2. Plot story authoring UX
   - Provide inline editor on plot show.
3. Reader UX polish
   - Smooth scroll anchors to focus link and add scroll progress.
4. Auth/permissions tightening
   - Ensure edit/create actions are consistently restricted to owners.

## Files of Interest
- Routes: `config/routes.rb`
- Reading flow: `app/controllers/reader_controller.rb`, `app/services/plot_story.rb`, `app/views/reader/show.html.erb`
- Plot elements: `app/controllers/plot_elements_controller.rb`, `app/views/plot_elements/new.html.erb`, `app/views/plots/show.html.erb`
- Revisions: `app/services/element_revision_manager.rb`
