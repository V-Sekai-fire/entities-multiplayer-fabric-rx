import Lake
open Lake DSL

package userflow

require «plausible-witness-dag» from git
  "https://github.com/V-Sekai-fire/plausible-witness-dag" @ "f18818941e8914b110f85ec330889a4785c01bf1"

@[default_target] lean_lib UserFlow where
  roots := #[`UserFlow, `Navigable]

@[default_target] lean_exe user_flow where
  root := `Main
