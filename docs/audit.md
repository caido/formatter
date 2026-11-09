# Formatter audit — 2026-10-28

This is the historical source audit. The treefmt-nix migration retains the audited project settings and file scopes, while package versions now come from `flake.lock`. See the current README for the migration's version changes.

The audit inspected default-branch file trees for all **169** repositories accessible in the Caido organization, including forks and archived repositories. None of the tree responses were truncated. It read **392** matching config/task/manifests from the **99 first-party repositories** (84 active, 15 archived). Forks were scanned for matching filenames and recorded in the inventory; upstream fork settings were not adopted as organization defaults.

Files inspected include formatter configs, ESLint configs containing Prettier integrations, Python project settings, package scripts/dependencies, mise tools/tasks, Makefiles and justfiles. Selected Nix shells and CI tasks were also checked. The inventory is evidence of the checked filenames and revisions, not proof that a formatter dependency is actively enforced. Generated/vendored paths were excluded from content inspection. Arbitrary custom scripts or CI workflow names outside these patterns may need a follow-up audit.

## Findings

| Tool             | Repositories / usage                                                                                          | Configuration differences                                                                  | Evidence                                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Oxfmt            | proxy-frontend, proxy-e2e, internal-services, mise-toolshed                                                   | 0.53.0 in proxy-frontend; 0.73.0 in proxy-e2e and mise-toolshed                            | [proxy-frontend/oxfmt.config.ts](https://github.com/caido/proxy-frontend/blob/f62fe3513faf4e8d21293d25825db7c0fbb80e4f/oxfmt.config.ts), [proxy-e2e/oxfmt.config.ts](https://github.com/caido/proxy-e2e/blob/96d77b8ab9f522ce297c52cfad6fa38974cfe9dd/oxfmt.config.ts), [mise-toolshed/.oxfmtrc.json](https://github.com/caido/mise-toolshed/blob/204c64626bb57ff214dce99f5d438fef83291d7b/.oxfmtrc.json)     |
| Prettier         | proxy-desktop, proxy-extension, proxy-playground, backend GraphQL, shared frontend projects                   | Multiple versions; backend GraphQL width 100; electron-updater width 180 and no semicolons | [proxy-backend/.prettierrc](https://github.com/caido/proxy-backend/blob/f8b300913ff61891ba25ca6b842f52b79eedfe92/.prettierrc), [proxy-desktop/package.json](https://github.com/caido/proxy-desktop/blob/ebf91544a58a8ae7b02cae170cf304920d9fdda9/package.json), [electron-updater/.prettierrc.yaml](https://github.com/caido/electron-updater/blob/02e1e9adc90542eb2174f1bc8424836e4e439f04/.prettierrc.yaml) |
| rustfmt          | proxy-backend, cloud-backend, sync-backend, student-backend, sqlite-rs, cogfer, convert; other Rust libraries | Pinned and floating nightlies; Module vs Crate imports; Rust 2021 and 2024                 | [proxy-backend/rustfmt.toml](https://github.com/caido/proxy-backend/blob/f8b300913ff61891ba25ca6b842f52b79eedfe92/rustfmt.toml), [sync-backend/rustfmt.toml](https://github.com/caido/sync-backend/blob/285b022d13a9eccd100b49fff086a8ad174a202f/rustfmt.toml), [sqlite-rs/rustfmt.toml](https://github.com/caido/sqlite-rs/blob/938ad8e6c9eae8d3b3e9a1122805a0f96fe6967c/rustfmt.toml)                       |
| Ruff             | analytics, caido-private                                                                                      | 0.16.9 / Python 3.12 vs 0.15.16 / Python 3.11; different source scopes                     | [analytics/ruff.toml](https://github.com/caido/analytics/blob/af124f8f39ac94204b4c4cac332c840ee2f61728/ruff.toml), [analytics/.mise/tasks/fmt/prod](https://github.com/caido/analytics/blob/af124f8f39ac94204b4c4cac332c840ee2f61728/.mise/tasks/fmt/prod), [caido-private/pyproject.toml](https://github.com/caido/caido-private/blob/4f60e99eee00a5894223c3005b6c8a1d43da09d8/pyproject.toml)               |
| OpenTofu         | infrastructure                                                                                                | 1.9.1; fmt under tofu/                                                                     | [infrastructure/mise.toml](https://github.com/caido/infrastructure/blob/ec721fefae4ea0645956f3cce3913045fc38a834/mise.toml), [infrastructure/justfile](https://github.com/caido/infrastructure/blob/ec721fefae4ea0645956f3cce3913045fc38a834/justfile)                                                                                                                                                        |
| shfmt and StyLua | mise-toolshed                                                                                                 | 3.14.1 and 2.6.0; shell files are detected by a source script                              | [mise-toolshed/scripts/format.mjs](https://github.com/caido/mise-toolshed/blob/204c64626bb57ff214dce99f5d438fef83291d7b/scripts/format.mjs), [mise-toolshed/.mise/config.toml](https://github.com/caido/mise-toolshed/blob/204c64626bb57ff214dce99f5d438fef83291d7b/.mise/config.toml)                                                                                                                        |
| Deno             | secrets-sync                                                                                                  | Project task runs deno fmt                                                                 | [secrets-sync/deno.json](https://github.com/caido/secrets-sync/blob/4192fc428c17f6e561cbae375ad67a17b279a9d2/deno.json)                                                                                                                                                                                                                                                                                       |
| nixfmt           | proxy-backend Nix environment                                                                                 | Installed tool, not an enforced formatting task; opt-in only                               | [proxy-backend/flake.nix](https://github.com/caido/proxy-backend/blob/f8b300913ff61891ba25ca6b842f52b79eedfe92/flake.nix)                                                                                                                                                                                                                                                                                     |
| SQLFluff         | cloud-backend; installed in backend environments                                                              | Postgres dialect; opt-in only                                                              | [cloud-backend/.sqlfluff](https://github.com/caido/cloud-backend/blob/8572b09230dc64a23b0a6342e2ed893707c9e5b6/.sqlfluff), [proxy-backend/flake.nix](https://github.com/caido/proxy-backend/blob/f8b300913ff61891ba25ca6b842f52b79eedfe92/flake.nix)                                                                                                                                                          |
| Black            | analytics-ingestion and cloud-cron (archived)                                                                 | 25.12.0 vs ^22.1.0; do not enable alongside Ruff                                           | [analytics-ingestion/pyproject.toml](https://github.com/caido/analytics-ingestion/blob/0c525fcc8c473a3ff64e13631a928a93f160d582/pyproject.toml), [cloud-cron/projects/download-statistics/pyproject.toml](https://github.com/caido/cloud-cron/blob/944f6ad3474cbf0b2c11fcc096fe96d461c40f79/projects/download-statistics/pyproject.toml)                                                                      |

## Adaptations in the shared presets

- The existing backend macro exclusion is moved from rustfmt's `ignore` option into treefmt. With a remote/shared rustfmt config, that option resolves against the config directory and can panic when source files are outside it. This was reproduced with the pinned nightly and fixed before publishing.
- `skip_children=true` prevents rustfmt from traversing child modules that treefmt deliberately excluded. Presets set the Rust edition explicitly; Cargo no longer supplies it implicitly.
- Shared Oxfmt JSON config carries the existing import groups. Source-specific generated files, E2E fixtures, and analytics' dbt transform app are excluded at the treefmt layer.
- Ruff lint rules, ESLint rules, and Clippy checks remain in their projects. This repository handles formatting only.
- The default profile selects one web engine and one Python engine. Prettier, Deno, and Black are alternatives, not additional passes on the same files.
- No source repository was modified or migrated as part of this change.

## First-party repository coverage

“Matched files” counts filenames matching the audit patterns, including manifests and task files. A match alone does not establish active formatting enforcement. Full filenames, commit SHAs, fork status, and archived status are in [inventory.json](inventory.json).

| Repository                                                                                                                      | Status   | Matched files |
| ------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------: |
| [.github](https://github.com/caido/.github/tree/e5a39d2939d5c7be9a13e9376a46844700a2adc4)                                       | Active   |             0 |
| [action-branch-name](https://github.com/caido/action-branch-name/tree/182b19bdc8ba9bf6023e2501b3c7dd806f349a1e)                 | Active   |             2 |
| [action-issue-triager](https://github.com/caido/action-issue-triager/tree/9a56e18f3375cb76b55401adc7ccfa9648a83d0f)             | Active   |             3 |
| [action-pr-target](https://github.com/caido/action-pr-target/tree/0152c3fb773e61a36ad6907dd809e7f0d70d2d46)                     | Active   |             2 |
| [actix-sse](https://github.com/caido/actix-sse/tree/7b737412030f206e4b7da5bbbaba10d8cc2bb441)                                   | Active   |             0 |
| [ai-ops](https://github.com/caido/ai-ops/tree/749620a84b3041b9e13fe88db3705dd34c5ffc26)                                         | Active   |            27 |
| [analytics](https://github.com/caido/analytics/tree/af124f8f39ac94204b4c4cac332c840ee2f61728)                                   | Active   |            34 |
| [analytics-ingestion](https://github.com/caido/analytics-ingestion/tree/0c525fcc8c473a3ff64e13631a928a93f160d582)               | Archived |             2 |
| [analytics-sync](https://github.com/caido/analytics-sync/tree/304124be3061306cd7498a244eb72dc8565ec02b)                         | Archived |             3 |
| [async_buf_read](https://github.com/caido/async_buf_read/tree/e3f641f5eadae7adda1c89269c6114271b280228)                         | Active   |             0 |
| [atlas](https://github.com/caido/atlas/tree/7efd2ad867233cad7cd7d66bfcdc07a6dbfa1bb9)                                           | Archived |             3 |
| [blog-frontend](https://github.com/caido/blog-frontend/tree/fab5baee3aad2ed92406be85f5bd58480d4c4778)                           | Active   |             0 |
| [bumpit](https://github.com/caido/bumpit/tree/bc5fca295a7e4108d83be95b9cd4ec1e6102dd11)                                         | Active   |             0 |
| [caido](https://github.com/caido/caido/tree/0844e045c160f4fa16579e929e769f72183335aa)                                           | Active   |             0 |
| [caido-action](https://github.com/caido/caido-action/tree/f3348ebe1db6db05eda3c455e6eede9729f56798)                             | Active   |             3 |
| [caido-box](https://github.com/caido/caido-box/tree/5f5842dff7967370837df9302340c463f6f6043f)                                   | Archived |             1 |
| [caido-codemirror](https://github.com/caido/caido-codemirror/tree/e1b4b2e78a3cf3dbb89c49a86daf2dc4f03a11b6)                     | Archived |             4 |
| [caido-dry-run](https://github.com/caido/caido-dry-run/tree/fe9c3d2176798c67aeacd369aa7f7baed136ae1b)                           | Active   |             3 |
| [caido-private](https://github.com/caido/caido-private/tree/4f60e99eee00a5894223c3005b6c8a1d43da09d8)                           | Active   |             9 |
| [capo](https://github.com/caido/capo/tree/dc49f6cce8699e4364b6ffa6d1df4de9ae6fef9d)                                             | Active   |             0 |
| [cloud-backend](https://github.com/caido/cloud-backend/tree/8572b09230dc64a23b0a6342e2ed893707c9e5b6)                           | Active   |            11 |
| [cloud-cron](https://github.com/caido/cloud-cron/tree/944f6ad3474cbf0b2c11fcc096fe96d461c40f79)                                 | Archived |             2 |
| [cogfer](https://github.com/caido/cogfer/tree/605e40ba154cd294886581a574e6b26ca3e21e3f)                                         | Active   |             2 |
| [common-frontend](https://github.com/caido/common-frontend/tree/c9cc2f39f7477a85e56eca53d4c0c24e72b8e396)                       | Active   |             5 |
| [convert](https://github.com/caido/convert/tree/3aefd155a1ad572bbf50ffe1a9c8edbeadf4c5ee)                                       | Active   |             4 |
| [dashboard-frontend](https://github.com/caido/dashboard-frontend/tree/2ebbb610b824426f9b3d14c21436729aaba58229)                 | Active   |             9 |
| [dependency-example](https://github.com/caido/dependency-example/tree/b58c9af13e6ccac5a9c474be3d3f48c563920856)                 | Active   |             1 |
| [design-system](https://github.com/caido/design-system/tree/4ab172f05a7683ef8a7f19f3210d8ff7bb27ee44)                           | Active   |             0 |
| [distribution](https://github.com/caido/distribution/tree/e12b2ff8ead5fbd7d982bc1ef8f6738f51cd60dd)                             | Active   |             0 |
| [doc-developer](https://github.com/caido/doc-developer/tree/7f9c39220f25f1f2f16fa04dafa4754fd82e77b7)                           | Active   |             7 |
| [documentation](https://github.com/caido/documentation/tree/c899c349022be87cf6b8f080840292f3f9a99c5c)                           | Active   |             7 |
| [download-backend](https://github.com/caido/download-backend/tree/9aa41e53278e1daa31838e65c7d4803039bfab20)                     | Active   |             3 |
| [dyper](https://github.com/caido/dyper/tree/fdaee1803436647a6dc286e3672bc1bf43cdb63c)                                           | Archived |             0 |
| [electron-updater](https://github.com/caido/electron-updater/tree/02e1e9adc90542eb2174f1bc8424836e4e439f04)                     | Active   |             3 |
| [emails](https://github.com/caido/emails/tree/3618163991602bb15f359da099a5cbd5dc836622)                                         | Active   |             5 |
| [engineering](https://github.com/caido/engineering/tree/b7bb836d703844bc15d2c06610821cb422ffcf4f)                               | Active   |             0 |
| [graphql-explorer](https://github.com/caido/graphql-explorer/tree/d9551063129599eaaf4ecb23152e6fb74ce9436f)                     | Active   |             4 |
| [httpql](https://github.com/caido/httpql/tree/f45361378be5c74ec1c5078fb8d4f83b2e9c6611)                                         | Active   |             5 |
| [infrastructure](https://github.com/caido/infrastructure/tree/ec721fefae4ea0645956f3cce3913045fc38a834)                         | Active   |             6 |
| [infrastructure-community](https://github.com/caido/infrastructure-community/tree/9e875aabcf5e6a9a2c46e421817925f26c9841c7)     | Active   |             0 |
| [infrastructure-dev](https://github.com/caido/infrastructure-dev/tree/b89b34ba4b465e41ef883c5063518b9a1eb8b741)                 | Active   |             1 |
| [infrastructure-staging](https://github.com/caido/infrastructure-staging/tree/8f24f6dbb696a36dc330126d36f96933fd253ea2)         | Active   |             3 |
| [integrations](https://github.com/caido/integrations/tree/f1b0a848daf600094956b52991635ae090ad39e0)                             | Active   |             0 |
| [internal-services](https://github.com/caido/internal-services/tree/bdc1ade8ab1a2843a730b24ffd18e45bbadc6d84)                   | Active   |            19 |
| [labs](https://github.com/caido/labs/tree/8e325bfcea86e707e7f941fd2cad56b721e5981b)                                             | Active   |             0 |
| [libsqlite3](https://github.com/caido/libsqlite3/tree/66154d6006067565d83f1d41e9e4e06edfd5385f)                                 | Active   |             0 |
| [ltree-sqlite](https://github.com/caido/ltree-sqlite/tree/669ff93d1fd3c0a253018b19ae31b7437271f4b8)                             | Active   |             4 |
| [management](https://github.com/caido/management/tree/15c8e65af8b2d7b0da8ac9ac4b62ef409ead7f70)                                 | Active   |             0 |
| [marketing-frontend](https://github.com/caido/marketing-frontend/tree/f217d4d17b0866ff2e12585e2eab2151202c50a1)                 | Active   |             8 |
| [mascot](https://github.com/caido/mascot/tree/4e11925d59c362e11d85a0ef21cac68dd10bfe92)                                         | Active   |             0 |
| [mise-toolshed](https://github.com/caido/mise-toolshed/tree/204c64626bb57ff214dce99f5d438fef83291d7b)                           | Active   |            11 |
| [nexus](https://github.com/caido/nexus/tree/b6d8343b4c6b05ef49e6ecf898a9eb923ce790a9)                                           | Active   |            14 |
| [nix-config](https://github.com/caido/nix-config/tree/2b7565df8957f9091be72111031c5bb10f662cd5)                                 | Active   |             1 |
| [operations](https://github.com/caido/operations/tree/98b865605bc5abf589a895b1438e5a3e731df55c)                                 | Active   |             5 |
| [orchestrator](https://github.com/caido/orchestrator/tree/7101bc1f68ecd76d835b0569594d0f0796c52a37)                             | Active   |             4 |
| [os_name](https://github.com/caido/os_name/tree/45c078dda3fdc3bbd008ba3802593e56d480ea35)                                       | Active   |             0 |
| [plugin-e2e](https://github.com/caido/plugin-e2e/tree/3c0be9ec9dfaec62c7017147434ab8fa2e5e8e62)                                 | Archived |             6 |
| [plugin-manifest](https://github.com/caido/plugin-manifest/tree/9269816f49851d143291123b4060e049fd7bb929)                       | Active   |             3 |
| [pnpm-deny](https://github.com/caido/pnpm-deny/tree/a77027a18d4b95e905d399e77abce136d98a9448)                                   | Active   |             7 |
| [process_alive](https://github.com/caido/process_alive/tree/297fc56029efc4acd7bb0753e1d07dd9b38ab531)                           | Active   |             0 |
| [proxy-backend](https://github.com/caido/proxy-backend/tree/f8b300913ff61891ba25ca6b842f52b79eedfe92)                           | Active   |            15 |
| [proxy-desktop](https://github.com/caido/proxy-desktop/tree/ebf91544a58a8ae7b02cae170cf304920d9fdda9)                           | Active   |            18 |
| [proxy-e2e](https://github.com/caido/proxy-e2e/tree/96d77b8ab9f522ce297c52cfad6fa38974cfe9dd)                                   | Active   |            19 |
| [proxy-extension](https://github.com/caido/proxy-extension/tree/2162848f1e9f5f77bfa4ffcc915f8309f9180465)                       | Active   |             6 |
| [proxy-frontend](https://github.com/caido/proxy-frontend/tree/f62fe3513faf4e8d21293d25825db7c0fbb80e4f)                         | Active   |            38 |
| [proxy-playground](https://github.com/caido/proxy-playground/tree/2c0af3b6d39156efca0cc315f049c19a0dd2cdbd)                     | Active   |             4 |
| [reglite](https://github.com/caido/reglite/tree/2b49ddb3f7eb73b1e54e47bd05d364fbbf1460a2)                                       | Active   |             0 |
| [renovate-config](https://github.com/caido/renovate-config/tree/1c891aef743b68af6d75fa65b723b9d7b68ab6e1)                       | Active   |             0 |
| [repro-tauri](https://github.com/caido/repro-tauri/tree/ac35e6e5b30838c9d4fb18bedd674a16cce8efaf)                               | Archived |             1 |
| [research](https://github.com/caido/research/tree/f064c46dc10cdaa02f47cbf6589d9589fef63f21)                                     | Active   |             1 |
| [resources](https://github.com/caido/resources/tree/1c49b86eba85cbd19ea8ce25ee8b1269cea6ae4e)                                   | Active   |             0 |
| [rswot](https://github.com/caido/rswot/tree/31629ecd892f0f97287d7a74c750e1b4fab8c46f)                                           | Active   |             0 |
| [sales](https://github.com/caido/sales/tree/5eaa35072f9ab8ae81348e0a3936b6ec84c0cc9f)                                           | Active   |             2 |
| [schemas](https://github.com/caido/schemas/tree/a95a014219dda1d4c1fef7cb9e2bfc4125d27cf8)                                       | Active   |             4 |
| [sdk-js](https://github.com/caido/sdk-js/tree/fb6ec06826144608791fb6d377bb5b8b26162022)                                         | Active   |            19 |
| [sea-jet](https://github.com/caido/sea-jet/tree/29c18ed0823e6e2570a9e01640407ca55c263d5b)                                       | Archived |             0 |
| [secrets-sync](https://github.com/caido/secrets-sync/tree/4192fc428c17f6e561cbae375ad67a17b279a9d2)                             | Active   |             4 |
| [serde-content-ref](https://github.com/caido/serde-content-ref/tree/fa1e323ae6beac6276d9974d8f68a228fbf662fc)                   | Active   |             0 |
| [shell_exec](https://github.com/caido/shell_exec/tree/14d946b6915eeb4f350b1f4fae2d7a87568077a8)                                 | Active   |             0 |
| [shift-backend](https://github.com/caido/shift-backend/tree/6142a79d4b39c1f7b7c87f3a8fd591a4f5aff23d)                           | Active   |             0 |
| [shift-marketing-frontend](https://github.com/caido/shift-marketing-frontend/tree/69d7c50d2125b00c3b95e0fba0d3d89b00a6db9b)     | Active   |             1 |
| [skills](https://github.com/caido/skills/tree/41697d8c647c3e61f6efdb3bf01cbfa66c27e2fd)                                         | Active   |             1 |
| [sqlite-rs](https://github.com/caido/sqlite-rs/tree/938ad8e6c9eae8d3b3e9a1122805a0f96fe6967c)                                   | Active   |             5 |
| [starterkit-plugin](https://github.com/caido/starterkit-plugin/tree/8f937841d4e29328f0cf6ce9b8a8cc221d332e00)                   | Archived |             3 |
| [starterkit-plugin-frontend](https://github.com/caido/starterkit-plugin-frontend/tree/85942c95fc3f96f2face8808e4e9c46be1cf3fd0) | Archived |             1 |
| [starterkit-workflow](https://github.com/caido/starterkit-workflow/tree/f39f0eb32bcfa1513ed4a7916e9a8738b6a68b5d)               | Archived |             1 |
| [store](https://github.com/caido/store/tree/13958088750a8aca200ef0b696cd9dc35b996a52)                                           | Active   |             2 |
| [student-backend](https://github.com/caido/student-backend/tree/201ddbb5e144ff4e4efbb18e449867b906952e5f)                       | Active   |             4 |
| [sync-backend](https://github.com/caido/sync-backend/tree/285b022d13a9eccd100b49fff086a8ad174a202f)                             | Active   |             4 |
| [sync-load-test](https://github.com/caido/sync-load-test/tree/7bd8036c2568fa0f49a8ea489ce6ebba955e1ce7)                         | Active   |             0 |
| [test-keyring](https://github.com/caido/test-keyring/tree/473837bfb7041f3b47c6c700e1ed52e62b76919d)                             | Archived |             0 |
| [test-tokio](https://github.com/caido/test-tokio/tree/2981efbe29ccaace609f1eecb38018e3d48b4f9a)                                 | Archived |             0 |
| [tls-impersonate](https://github.com/caido/tls-impersonate/tree/5924931c83285864481b48853d5f90cd42802d86)                       | Active   |             0 |
| [typescript-configs](https://github.com/caido/typescript-configs/tree/f3fa965cbfb327c7f20812309bd27ea2ae43644a)                 | Active   |             9 |
| [ui-kit](https://github.com/caido/ui-kit/tree/5f03919bc81ce634d754adfd1fc34907bdf9f400)                                         | Active   |            10 |
| [windows-setup](https://github.com/caido/windows-setup/tree/6ab48016eb4fc4316aaec2db43e5841310f1e6eb)                           | Active   |             0 |
| [workshop-defcon](https://github.com/caido/workshop-defcon/tree/3dd1d313a2400b5f2837426a6141717efa4e5c05)                       | Active   |             0 |
| [workshop-demo](https://github.com/caido/workshop-demo/tree/bdc413b9ffe4f915ae0a5912425a6cd840a3f7a6)                           | Active   |             1 |
| [workshop-hackfest](https://github.com/caido/workshop-hackfest/tree/81c2ee2a7cc17a47105f25fe312fd23effad28b2)                   | Active   |            14 |
