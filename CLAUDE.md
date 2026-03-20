# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/dev                  # Start development server
bin/rails test           # Run all unit & integration tests
bin/rails test:system    # Run system/E2E tests
bin/rails test TEST=test/path/to/specific_test.rb  # Run a single test file
bin/rubocop              # Lint Ruby code (Rails Omakase style)
bin/brakeman             # Security scan
bin/rails db:prepare     # Create and migrate databases
bin/rails db:seed        # Load seed data
```

## Architecture

**Dalloway** is a Rails 8.1 AI-powered interview preparation platform. Users import job offers, practice mock interviews via AI chat, and generate cover letters.

### Core Flows

**Job Offers** — Users import offers from HelloWork URLs. `OfferScraper` / `HelloWorkScraper` use Nokogiri to extract title, description, salary, experience level, etc.

**Mock Interviews (Chats)** — A `Chat` belongs to a `User` and an `Offer`. On creation, the AI generates an opening question tailored to the user profile + offer details. Users exchange `Message` records (role: `user`/`assistant`/`system`). After every 3 user messages, the system injects intermediate feedback. A final comprehensive feedback is generated on chat end.

**Cover Letters** — `GenerateCoverLetterJob` runs async and uses `CvReader` to extract text from the user's uploaded PDF CV, then calls the LLM to draft a personalized letter. Results are pushed to the browser via Turbo Stream broadcasts.

### Key Model Relationships

```
User ──< Chat ──< Message
     ──< CoverLetter
     ──< Application
     has_one_attached :cv, :photo

Offer ──< Chat
      ──< CoverLetter
      ──< Application
```

### AI Integration

`ruby_llm` wraps OpenAI API calls. Configuration is in `config/initializers/ruby_llm.rb`. Prompts are built inline in the service/job layer, incorporating user profile fields and offer details as context.

### Real-time UX

Hotwire (Turbo + Stimulus) handles all live updates. Cover letter generation streams progress back via `Turbo::StreamsChannel`. No full-page reloads for chat interactions.

### Infrastructure

- **Asset pipeline:** Propshaft + Importmap (no Node/bundler required)
- **Background jobs:** Solid Queue (configured in `config/queue.yml`)
- **Caching:** Solid Cache; **WebSockets:** Solid Cable
- **Deployment:** Kamal + Docker (`Dockerfile`, `.kamal/`)
- **CI:** `.github/workflows/ci.yml` — runs Brakeman, bundler-audit, RuboCop, unit tests, and system tests against PostgreSQL
