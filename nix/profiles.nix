# Audited file routing. Style settings are shared through nix/settings.nix.
{
  "proxy-frontend" = {
    "formatters" = {
      "oxfmt" = {
        "includes" = [
          "packages/*.ts"
          "packages/*.tsx"
          "packages/*.vue"
          "packages/*.js"
          "packages/*.mjs"
          "packages/*.cjs"
          "packages/*.json"
          "packages/*.css"
          "packages/*.scss"
          "packages/*.graphql"
          "packages/*.md"
          "packages/*.yml"
          "packages/*.yaml"
          "packages/*.html"
          "scripts/*.ts"
          "scripts/*.mjs"
          "scripts/*.js"
          ".github/*.yml"
          ".github/*.yaml"
        ];
        "excludes" = [
          "*.svg"
          "*.grammar"
        ];
        "style" = "default";
      };
      "oxfmt-root" = {
        "includes" = [
          "*.ts"
          "*.mjs"
          "*.js"
          "*.json"
          "*.yml"
          "*.yaml"
        ];
        "excludes" = [
          "*/*"
        ];
        "style" = "default";
      };
    };
    "excludes" = [
      "packages/ui/src/@types/modules/vue-router.d.ts"
    ];
  };
  "proxy-backend" = {
    "formatters" = {
      "rustfmt" = {
        "includes" = [
          "*.rs"
        ];
        "excludes" = [
          "proxy-tests/tests/common/macros/*"
        ];
        "style" = "proxy-backend";
        "edition" = "2024";
      };
      "prettier" = {
        "includes" = [
          "*.graphql"
        ];
        "style" = "backend";
      };
    };
  };
  "proxy-desktop" = {
    "formatters" = {
      "prettier" = {
        "includes" = [
          "packages/main/src/*.ts"
          "packages/main/src/*.js"
          "packages/ui/src/*.ts"
          "packages/ui/src/*.js"
          "packages/ui/src/*.vue"
          "packages/shared/src/*.ts"
          "packages/shared/src/*.js"
          "packages/migrations/src/*.ts"
          "packages/migrations/src/*.js"
        ];
        "style" = "default";
      };
    };
  };
  "proxy-playground" = {
    "formatters" = {
      "prettier" = {
        "includes" = [
          "*.ts"
          "*.tsx"
          "*.mts"
          "*.cts"
          "*.js"
          "*.jsx"
          "*.mjs"
          "*.cjs"
          "*.vue"
          "*.html"
          "*.css"
          "*.scss"
          "*.json"
          "*.jsonc"
          "*.graphql"
          "*.md"
          "*.yml"
          "*.yaml"
        ];
        "style" = "default";
      };
    };
  };
  "postgres" = {
    "formatters" = {
      "sqlfluff" = {
        "includes" = [
          "*.sql"
        ];
      };
    };
  };
  "self" = {
    "formatters" = {
      "prettier" = {
        "includes" = [
          "*.json"
          "*.yaml"
          "*.yml"
          "*.md"
        ];
        "excludes" = [
          "tests/*"
        ];
        "style" = "default";
      };
      "nixfmt" = {
        "includes" = [
          "*.nix"
        ];
      };
      "ruff" = {
        "includes" = [
          "tests/*.py"
        ];
        "style" = "default";
      };
      "shfmt" = {
        "includes" = [
          "bin/format"
          ".mise/tasks/*"
        ];
      };
    };
  };
  "cogfer" = {
    "formatters" = {
      "rustfmt" = {
        "includes" = [
          "*.rs"
        ];
        "excludes" = [
          "proxy-tests/tests/common/macros/*"
        ];
        "style" = "cogfer";
        "edition" = "2024";
      };
    };
  };
  "analytics-ingestion" = {
    "formatters" = {
      "black" = {
        "includes" = [
          "src/*.py"
          "src/*.pyi"
        ];
      };
    };
  };
  "proxy-extension" = {
    "formatters" = {
      "prettier" = {
        "includes" = [
          "*.ts"
          "*.tsx"
          "*.mts"
          "*.cts"
          "*.js"
          "*.jsx"
          "*.mjs"
          "*.cjs"
          "*.vue"
          "*.html"
          "*.css"
          "*.scss"
          "*.json"
          "*.jsonc"
          "*.graphql"
          "*.md"
          "*.yml"
          "*.yaml"
        ];
        "style" = "default";
      };
    };
  };
  "sqlite-rs" = {
    "formatters" = {
      "rustfmt" = {
        "includes" = [
          "*.rs"
        ];
        "excludes" = [
          "proxy-tests/tests/common/macros/*"
        ];
        "style" = "sqlite-rs";
        "edition" = "2024";
      };
    };
  };
  "infrastructure" = {
    "formatters" = {
      "tofu" = {
        "includes" = [
          "tofu/*.tf"
          "tofu/*.tfvars"
          "tofu/*.tftest.hcl"
        ];
      };
    };
  };
  "mise-toolshed" = {
    "formatters" = {
      "oxfmt" = {
        "includes" = [
          "*.ts"
          "*.tsx"
          "*.mts"
          "*.cts"
          "*.js"
          "*.jsx"
          "*.mjs"
          "*.cjs"
          "*.vue"
          "*.html"
          "*.css"
          "*.scss"
          "*.json"
          "*.jsonc"
          "*.graphql"
          "*.md"
          "*.yml"
          "*.yaml"
        ];
        "excludes" = [
          "*.svg"
          "*.grammar"
        ];
        "style" = "toolshed";
      };
      "shfmt" = {
        "includes" = [
          "*.sh"
          "*.bash"
          "*.bats"
        ];
      };
      "stylua" = {
        "includes" = [
          "*.lua"
          "*.luau"
        ];
      };
    };
    "excludes" = [
      ".mise/locks/*"
    ];
  };
  "student-backend" = {
    "formatters" = {
      "rustfmt" = {
        "includes" = [
          "*.rs"
        ];
        "excludes" = [
          "proxy-tests/tests/common/macros/*"
        ];
        "style" = "student-backend";
        "edition" = "2024";
      };
    };
  };
  "internal-services" = {
    "formatters" = {
      "oxfmt" = {
        "includes" = [
          "packages/*.ts"
          "packages/*.tsx"
          "packages/*.vue"
          "packages/*.js"
          "packages/*.mjs"
          "packages/*.cjs"
          "packages/*.json"
          "packages/*.css"
          "packages/*.html"
          "apps/*.ts"
          "apps/*.json"
          "scripts/*.ts"
          "scripts/*.mjs"
          "scripts/*.js"
          ".github/*.yml"
          ".github/*.yaml"
        ];
        "excludes" = [
          "*.svg"
          "*.grammar"
        ];
        "style" = "default";
      };
      "oxfmt-root" = {
        "includes" = [
          "*.ts"
          "*.mjs"
          "*.js"
          "*.json"
          "*.yml"
          "*.yaml"
        ];
        "excludes" = [
          "*/*"
        ];
        "style" = "default";
      };
    };
  };
  "nix" = {
    "formatters" = {
      "nixfmt" = {
        "includes" = [
          "*.nix"
        ];
      };
    };
  };
  "convert" = {
    "formatters" = {
      "rustfmt" = {
        "includes" = [
          "*.rs"
        ];
        "excludes" = [
          "proxy-tests/tests/common/macros/*"
        ];
        "style" = "convert";
        "edition" = "2021";
      };
    };
  };
  "analytics" = {
    "formatters" = {
      "ruff" = {
        "includes" = [
          "apps/event_consumer/*.py"
          "apps/event_consumer/*.pyi"
          "apps/extract_and_load/*.py"
          "apps/extract_and_load/*.pyi"
          "apps/reconcile/*.py"
          "apps/reconcile/*.pyi"
          "apps/reverse_etl/*.py"
          "apps/reverse_etl/*.pyi"
        ];
        "style" = "analytics";
      };
    };
    "excludes" = [
      "apps/transform/*"
    ];
  };
  "caido-private" = {
    "formatters" = {
      "ruff" = {
        "includes" = [
          "scripts/*.py"
          "scripts/*.pyi"
          "tests/*.py"
          "tests/*.pyi"
        ];
        "style" = "caido-private";
      };
    };
  };
  "cloud-backend" = {
    "formatters" = {
      "rustfmt" = {
        "includes" = [
          "*.rs"
        ];
        "excludes" = [
          "proxy-tests/tests/common/macros/*"
        ];
        "style" = "cloud-backend";
        "edition" = "2024";
      };
      "prettier" = {
        "includes" = [
          "*.graphql"
        ];
        "style" = "default";
      };
    };
  };
  "electron-updater" = {
    "formatters" = {
      "prettier" = {
        "includes" = [
          "*.ts"
          "*.tsx"
          "*.mts"
          "*.cts"
          "*.js"
          "*.jsx"
          "*.mjs"
          "*.cjs"
          "*.vue"
          "*.html"
          "*.css"
          "*.scss"
          "*.json"
          "*.jsonc"
          "*.graphql"
          "*.md"
          "*.yml"
          "*.yaml"
        ];
        "style" = "electron-updater";
      };
    };
  };
  "proxy-e2e" = {
    "formatters" = {
      "oxfmt" = {
        "includes" = [
          "*.ts"
          "*.js"
          "*.mjs"
        ];
        "excludes" = [
          "*.svg"
          "*.grammar"
        ];
        "style" = "default";
      };
    };
    "excludes" = [
      "plugins/*"
      "test-results/*"
      "playwright-report/*"
      "binaries/*"
    ];
  };
  "secrets-sync" = {
    "formatters" = {
      "deno" = {
        "includes" = [
          "*.ts"
          "*.tsx"
          "*.js"
          "*.jsx"
          "*.json"
          "*.jsonc"
          "*.md"
        ];
      };
    };
  };
  "sync-backend" = {
    "formatters" = {
      "rustfmt" = {
        "includes" = [
          "*.rs"
        ];
        "excludes" = [
          "proxy-tests/tests/common/macros/*"
        ];
        "style" = "sync-backend";
        "edition" = "2021";
      };
    };
  };
  "cloud-cron" = {
    "formatters" = {
      "black" = {
        "includes" = [
          "*.py"
          "*.pyi"
        ];
      };
    };
  };
  "infrastructure-yaml" = {
    "formatters" = {
      "prettier" = {
        "includes" = [
          "*.yaml"
          "*.yml"
        ];
        "style" = "infrastructure";
      };
    };
  };
  "default" = {
    "formatters" = {
      "oxfmt" = {
        "includes" = [
          "*.ts"
          "*.tsx"
          "*.mts"
          "*.cts"
          "*.js"
          "*.jsx"
          "*.mjs"
          "*.cjs"
          "*.vue"
          "*.html"
          "*.css"
          "*.scss"
          "*.json"
          "*.jsonc"
          "*.graphql"
          "*.md"
          "*.yml"
          "*.yaml"
        ];
        "excludes" = [
          "*.svg"
          "*.grammar"
        ];
        "style" = "default";
      };
      "rustfmt" = {
        "includes" = [
          "*.rs"
        ];
        "excludes" = [
          "proxy-tests/tests/common/macros/*"
        ];
        "style" = "default";
        "edition" = "2024";
      };
      "ruff" = {
        "includes" = [
          "*.py"
          "*.pyi"
          "*.ipynb"
        ];
        "style" = "default";
      };
      "tofu" = {
        "includes" = [
          "*.tf"
          "*.tfvars"
          "*.tftest.hcl"
        ];
      };
      "shfmt" = {
        "includes" = [
          "*.sh"
          "*.bash"
          "*.bats"
        ];
      };
      "stylua" = {
        "includes" = [
          "*.lua"
          "*.luau"
        ];
      };
    };
  };
}
