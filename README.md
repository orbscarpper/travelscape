Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

## Local setup

Copy `.env.example` to `.env` and replace the placeholder with your OpenAI API key:

```bash
cp .env.example .env
bin/setup
```

The app reads `OPENAI_API_KEY` through `config/initializers/ruby_llm.rb`. Never commit `.env` or expose the key in source code.
