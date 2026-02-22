# Narrativerse Agent Notes

## Current Status
- Rails 8 app scaffolding complete with SQLite DB.
- Core models and migrations for User, Plot, Scene, Element, ElementRevision, PlotElement, PlotSceneLink, PlotParentLink.
- Minimal UI for home, plots, scenes, elements, plot reading, and plot element management.
- Services in place: PlotBuilder, PlotNavigation, PlotForker, ElementRevisionManager.
- Tests added for PlotBuilder, PlotForker, PlotSceneLinksController, ElementRevisionManager.

## Recent Commits
- ff35b29 Sync element revisions and prune orphans
- 5ca80bd Refine element revisions and flash feedback
- f21a0ac Add plot element management and fork service
- 984ec9e Pin minitest and cover plot navigation

## How to Run
- Ruby via mise: `/home/vscode/.local/bin/mise exec -- ruby -v`
- Run tests: `/home/vscode/.local/bin/mise exec -- bin/rails test`

## Important Implementation Details
- Reading URL: `/plots/:plot_id/plot_scene_links/:id` (nested route).
- PlotBuilder finds previous scene across parent plots and exposes `previous_link`/`next_link` for navigation.
- PlotForker duplicates a plot from a specific scene and links to parent plot.
- ElementRevisionManager updates owned plot elements to latest revision and prunes unreferenced revisions.

## TODO / Next Steps
1. Strengthen branching UI
   - Show branch metadata (author, summary, count of scenes).
   - Add jump to branch from reading screen with more context.
2. Auth/permissions tightening
   - Ensure edit/create actions are consistently restricted to owners.
   - Add guardrails to PlotElement removal and element edits for non-owners.
3. UX polish
   - Add pagination or search on plots/scenes/elements index.
   - Flash messages already added; consider inline validation messages.
4. AI assist hooks
   - Placeholder endpoints/UI for AI summary generation in Element/Plot/Scene forms.

## Files of Interest
- Routes: `config/routes.rb`
- Reading flow: `app/controllers/plot_scene_links_controller.rb`, `app/services/plot_builder.rb`, `app/views/plot_scene_links/show.html.erb`
- Plot elements: `app/controllers/plot_elements_controller.rb`, `app/views/plot_elements/new.html.erb`, `app/views/plots/show.html.erb`
- Revisions: `app/services/element_revision_manager.rb`
