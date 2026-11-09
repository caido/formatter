# Formatter settings are serialized into immutable JSON/TOML files in the Nix store.
{
  "oxfmt" = {
    "default" = {
      "printWidth" = 80;
      "sortImports" = {
        "groups" = [
          "builtin"
          "external"
          "internal"
          "parent"
          "sibling"
          "index"
        ];
        "newlinesBetween" = true;
        "ignoreCase" = true;
        "order" = "asc";
      };
    };
    "generated" = {
      "printWidth" = 80;
      "sortImports" = false;
    };
    "toolshed" = {
      "ignorePatterns" = [
        "pnpm-lock.yaml"
        "dist/"
        "node_modules/"
        ".agents/"
        ".mise/locks/"
      ];
    };
  };
  "prettier" = {
    "infrastructure" = {
      "overrides" = [
        {
          "files" = [
            "*.yaml"
            "*.yml"
          ];
          "options" = {
            "singleQuote" = true;
          };
        }
      ];
    };
    "default" = {
      "tabWidth" = 2;
      "useTabs" = false;
      "printWidth" = 80;
      "singleQuote" = false;
      "semi" = true;
      "trailingComma" = "all";
      "arrowParens" = "always";
    };
    "backend" = {
      "overrides" = [
        {
          "files" = [
            "*.graphql"
          ];
          "options" = {
            "tabWidth" = 2;
            "useTabs" = false;
            "printWidth" = 100;
          };
        }
      ];
    };
    "electron-updater" = {
      "singleQuote" = false;
      "semi" = false;
      "arrowParens" = "avoid";
      "trailingComma" = "es5";
      "printWidth" = 180;
      "quoteProps" = "as-needed";
    };
  };
  "rustfmt" = {
    "default" = {
      "unstable_features" = true;
      "edition" = "2024";
      "single_line_if_else_max_width" = 80;
      "group_imports" = "StdExternalCrate";
      "imports_granularity" = "Module";
      "error_on_line_overflow" = false;
      "error_on_unformatted" = false;
    };
    "proxy-backend" = {
      "unstable_features" = true;
      "edition" = "2024";
      "single_line_if_else_max_width" = 80;
      "group_imports" = "StdExternalCrate";
      "imports_granularity" = "Module";
      "error_on_line_overflow" = false;
      "error_on_unformatted" = false;
    };
    "cogfer" = {
      "single_line_if_else_max_width" = 80;
      "group_imports" = "StdExternalCrate";
      "imports_granularity" = "Module";
    };
    "sqlite-rs" = {
      "unstable_features" = true;
      "group_imports" = "StdExternalCrate";
      "imports_granularity" = "Crate";
      "reorder_imports" = true;
    };
    "student-backend" = {
      "single_line_if_else_max_width" = 80;
      "group_imports" = "StdExternalCrate";
      "imports_granularity" = "module";
    };
    "convert" = {
      "group_imports" = "StdExternalCrate";
    };
    "cloud-backend" = {
      "single_line_if_else_max_width" = 80;
      "group_imports" = "StdExternalCrate";
      "imports_granularity" = "Module";
    };
    "sync-backend" = {
      "single_line_if_else_max_width" = 80;
      "group_imports" = "StdExternalCrate";
      "imports_granularity" = "module";
    };
  };
  "ruff" = {
    "caido-private" = {
      "line-length" = 88;
      "target-version" = "py311";
    };
    "default" = {
      "line-length" = 88;
      "target-version" = "py312";
    };
    "analytics" = {
      "line-length" = 88;
      "target-version" = "py312";
      "extend-exclude" = [
        "apps/transform"
      ];
    };
  };
}
