# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Start the dev server
bin/rails server

# Run all tests
bin/rails test

# Run a single test file
bin/rails test test/models/question_test.rb

# Run a single test by line number
bin/rails test test/models/question_test.rb:42

# Database
bin/rails db:migrate
bin/rails db:seed          # creates admin@example.com / password123 + sample set
bin/rails db:schema:load   # faster reset from schema.rb

# Rails console
bin/rails console

# Run the numeric_approximate smoke test (in tmp/)
bin/rails runner tmp/numeric_approx_test.rb
```

Requires Ruby 3.4.2 (see `.ruby-version`). Rails 8.1 is incompatible with Ruby 3.3.

## Architecture

Single-developer Rails 8.1 app. SQLite, Propshaft, Hotwire/Turbo, Devise. No React, no custom JS beyond Stimulus. Ruthless simplicity is the primary constraint.

### Core flow

1. Users create **QuestionSets** (with a `looseness` enum controlling answer-matching strictness).
2. **Questions** belong to a QuestionSet and have `body` + `answer` text fields.
3. Study mode (`GET /question_sets/:id/study`) serves a single Turbo-powered page. Submitting an answer POSTs to `check_answer`, which returns a `turbo_stream` response that updates three DOM regions inline — no page reload.
4. **Attempts** are written per answer for logged-in users (nullable `user_id`; anonymous users generate no Attempt rows at all).

### Answer matching (`app/models/question.rb`)

All matching logic lives in `Question#correct?(submitted)`. The `looseness` enum on `QuestionSet` controls which path runs:

| Looseness | Behaviour |
|---|---|
| `exact` | String equality |
| `case_insensitive` | `downcase` both sides |
| `fuzzy` | `normalize()` (strip punctuation, collapse whitespace) + float epsilon fallback |
| `very_fuzzy` | Fuzzy + Levenshtein ≤ max(20% of answer length, 1), capped at 3 |
| `numeric_approximate` | `parse_magnitude()` strips currency symbols and word/letter multipliers (trillion/billion/million/thousand/hundred and t/b/m/k), then checks ≤ 5% relative error; falls back to normalized string equality |

`parse_magnitude` checks multiplier suffixes longest-first (so "trillion" matches before bare "t").

### Weighted random study selection

```ruby
weight = 1.0 - (accuracy * 0.8)   # range [0.2, 1.0]
```

Uses the rolling 30-day accuracy from `Attempt` rows. Anonymous users and questions with no history get `accuracy = 0.5` (neutral weight `0.6`). No question is ever excluded.

### Question editor

`/question_sets/:id/questions` renders all Q&A rows as Turbo Frames. Add/edit/delete operate inline via `create.turbo_stream.erb` and `update.turbo_stream.erb`.

### Study mode Turbo structure

`study.html.erb` has three separately-addressable DOM regions:

- `#answer-feedback` — updated with `turbo_stream.update` (preserves element for repeated updates)
- `#question-card` — replaced with `turbo_stream.replace` (the partial re-wraps the ID)
- `#session-stats` — updated with `turbo_stream.update` (auth users only)

**Important:** Use `turbo_stream.update` (not `.replace`) for `answer-feedback` and `session-stats`. `.replace` removes the element from the DOM, so subsequent Turbo updates can't find it by ID.

### JSON import (`/question_sets/import`)

Accepts pasted JSON or a `.json` file upload. See `QuestionsController#build_from_json` for validation logic. Question fields accept either `"question"` or `"body"` as the prompt key. Invalid `looseness` values silently default to `case_insensitive`.

### Authorization

- `authenticate_user!` guards: index, new, create, edit, update, destroy, pin, import
- `study` and `check_answer` are intentionally public
- Owner check: `@question_set.user == current_user`
- Admin check: `current_user.admin?` (boolean column on users)
- `pin` action toggles between `:listed` and `:pinned` visibility

### Visibility / landing page

`QuestionSet` has a `visibility` enum: `draft (0)`, `listed (1)`, `pinned (2)`. The landing page (`pages#landing`) shows sets scoped to `visible_to_all` (listed + pinned), with pinned sets featured. Only admins can toggle pin via `PATCH /question_sets/:id/pin`.
