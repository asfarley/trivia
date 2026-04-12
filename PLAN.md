# Memorization Assistant App — Rails 8

## Context

A single-developer Rails app for memorizing question/answer pairs via flashcard-style study sessions. Hosted and maintained by one person — ruthless simplicity is the primary architectural constraint. Users can create question sets, study them with weighted-random question selection (harder questions appear more often), and track accuracy over time. Anonymous (unauthenticated) study is supported; accuracy is only tracked for logged-in users.

---

## Tech Stack

- **Rails 8** (latest), SQLite, Puma
- **Devise** for authentication
- **Hotwire/Turbo + Stimulus** (bundled with Rails 8) for inline editing and study mode — no React, no custom JS beyond Stimulus controllers
- **Gems added beyond Rails defaults:** `devise` only

---

## Models

### `users` (Devise-managed)
Minimal Devise install: email + password only. Add one boolean column: `admin: boolean, default: false`.

### `question_sets`
```
user_id          integer, nullable (optional: true)
title            string, not null
description      text
published        boolean, default: false   -- visible to anonymous users
pinned           boolean, default: false   -- shown on landing page
looseness        integer, default: 1       -- enum: exact/case_insensitive/fuzzy/very_fuzzy
rolling_days     integer, default: 30      -- window for rolling accuracy stats
```
Enums: `{ exact: 0, case_insensitive: 1, fuzzy: 2, very_fuzzy: 3 }`

### `questions`
```
question_set_id  integer, not null
body             text, not null
answer           text, not null
position         integer
```

### `attempts`
```
question_id      integer, not null
user_id          integer, nullable    -- null = anonymous, never written
correct          boolean, not null
answered_at      datetime, not null
```
Anonymous users: `Attempt.create!` is skipped entirely. No session tokens, no tracking.

### Associations
```ruby
User        has_many :question_sets, has_many :attempts
QuestionSet belongs_to :user, optional: true
            has_many :questions, dependent: :destroy
Question    belongs_to :question_set
            has_many :attempts, dependent: :destroy
Attempt     belongs_to :question, belongs_to :user, optional: true
```

### Accuracy: computed, never cached
```ruby
# All-time
Attempt.where(question_id: id, user_id: uid).group(:correct).count
# Rolling
Attempt.where(question_id: id, user_id: uid, answered_at: 30.days.ago..).group(:correct).count
```

---

## Routes and Pages

```ruby
root "pages#landing"
devise_for :users

resources :question_sets do
  member do
    get  :study
    post :check_answer    # Turbo Stream response
    patch :pin            # admin-only toggle
  end
  resources :questions, only: [:index, :create, :update, :destroy]
end
```

| Page | Auth | Purpose |
|---|---|---|
| `/` | Public | Landing: pinned + published sets |
| `/question_sets` | Required | User's own sets |
| `/question_sets/new` | Required | Create set |
| `/question_sets/:id/edit` | Required (owner) | Edit set metadata |
| `/question_sets/:id/questions` | Required (owner) | Inline Q&A editor |
| `/question_sets/:id/study` | Public | Study mode |

---

## Answer Matching — `app/services/answer_checker.rb`

Pure Ruby, no gems.

| Looseness | Behavior |
|---|---|
| `exact` | `a == b` |
| `case_insensitive` | `a.downcase == b.downcase` |
| `fuzzy` | Normalize both: downcase + strip punctuation + collapse whitespace |
| `very_fuzzy` | Fuzzy normalization + Levenshtein distance ≤ 20% of answer length (min 1) |

For numeric answers: parse both sides as floats (epsilon 0.01) before string comparison in `fuzzy`+.
For dates: attempt `Date.parse` on both sides before string comparison.

---

## Weighted Random Study Mode

```
Weight = 1.0 - (accuracy * 0.8), range [0.2, 1.0]
0% accuracy  → weight 1.0 (most likely)
100% accuracy → weight 0.2 (still appears, just rarely)
Anonymous    → neutral 0.5 accuracy (uniform random, no tracking)
```

Weighted pick: sum all weights, pick `rand * total`, walk the list cumulatively. Rolling window controlled by `question_set.rolling_days`.

Study mode is a single Turbo-powered page. Submitting an answer POSTs to `check_answer`, which returns a Turbo Stream updating feedback, score, and the next question inline.

---

## Question Editor

`/question_sets/:id/questions` renders all Q&A rows as Turbo Frames. Each row: editable body + answer fields, save (PATCH inside frame), delete (DELETE removes frame). "Add row" appends a new blank frame. Stock Hotwire.

---

## Landing Page

```ruby
QuestionSet.where(pinned: true, published: true).order(updated_at: :desc)
```

`pinned` toggled by admin users via `PATCH /question_sets/:id/pin`.

---

## Build Order

1. `rails new` with `--database=sqlite3 --asset-pipeline=propshaft`
2. Install + configure Devise
3. Migrations: `question_sets`, `questions`, `attempts` (+ `admin` column on `users`)
4. Models, associations, enums, validations
5. `AnswerChecker` service
6. Routes
7. Question set CRUD + question inline editor
8. Study mode (study page + check_answer Turbo Stream)
9. Landing page with pinned sets
10. Accuracy stats display on question set show page

---

## Critical Files

```
db/migrate/
app/models/{user,question_set,question,attempt}.rb
app/services/answer_checker.rb
app/controllers/question_sets_controller.rb
app/controllers/questions_controller.rb
app/views/question_sets/study.html.erb
app/views/question_sets/check_answer.turbo_stream.erb
app/views/questions/index.html.erb
config/routes.rb
```

---

## Verification

1. **Auth flow:** register, log in, log out; unauthenticated users cannot reach `/question_sets` or edit pages
2. **Editor:** create a question set, add/edit/delete questions inline without full page reload
3. **Answer checking:** test each looseness level with exact, near-miss, and wrong answers
4. **Study mode:** Turbo Stream updates inline; attempts written for logged-in users, skipped for anonymous
5. **Weighted distribution:** low-accuracy questions appear more frequently over ~50 rounds
6. **Landing page:** pin a set → appears; unpin → disappears
7. **Anonymous mode:** no `attempts` rows written
