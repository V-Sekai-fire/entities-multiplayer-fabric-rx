import Lake
open Lake DSL

package userflow

require «plausible-witness-dag» from git
  "https://github.com/V-Sekai-fire/plausible-witness-dag" @ "23ca437da267d835eab00e7ad9e483c6e000207b"

@[default_target] lean_lib UserFlow where
  roots := #[`UserFlow, `Navigable]

@[default_target] lean_exe user_flow where
  root := `Main
