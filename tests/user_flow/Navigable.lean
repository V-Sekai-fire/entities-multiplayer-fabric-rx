import PlausibleWitnessDag
import UserFlow

/-! Every path through the user flow is navigable: for each node, a path to it from launch and a
path from it to an outcome are found as witnesses on plausible-witness-dag's ladder. -/

namespace UserFlow.Navigable

open PlausibleWitnessDag UserFlow

abbrev Edges := List (N × N × String)

/-- L0 walks as far as the hub; L1 reaches the deepest screen. -/
def levels : Array Level := #[
  { idx := 0, walkSteps := 6, finBound := 256, numInst := 200 },
  { idx := 1, walkSteps := 16, finBound := 256, numInst := 200 }]

def encode (n : N) : Nat := idx n all

/-- The first shortest path from `start` to a node meeting `goal`, within `steps` moves. -/
def walk (es : Edges) (steps : Nat) (start : N) (goal : N → Bool) : Option (List N) := Id.run do
  let mut frontier : List (List N) := [[start]]
  let mut seen : List N := [start]
  let mut depth := 0
  let mut found : Option (List N) := none
  while found.isNone && depth <= steps && !frontier.isEmpty do
    let mut next : List (List N) := []
    for path in frontier do
      let cur := path.getLastD start
      if found.isNone && goal cur then
        found := some path
      else if depth < steps then
        for s in succsOf es cur do
          if !seen.contains s then
            seen := s :: seen
            next := next ++ [path ++ [s]]
    frontier := next
    depth := depth + 1
  found

structure Query where
  name : String
  start : N
  goal : N → Bool
  target : N

def readback (es : Edges) (q : Query) (steps : Nat) : Readback (List N) :=
  match walk es steps q.start q.goal with
  | some path => { value := path, found := true, witnessIdx := encode q.target, budgetHit := false }
  | none => { value := [], found := false, budgetHit := (walk es all.length q.start q.goal).isSome }

def candidate (es : Edges) (q : Query) (lvl : Level) (c : Nat) : Bool :=
  c == encode q.target && (walk es lvl.walkSteps q.start q.goal).isSome

def fromLaunch (n : N) : Query :=
  { name := s!"{nameOf n} from launch", start := .launch, goal := (· == n), target := n }

def toOutcome (n : N) : Query :=
  { name := s!"{nameOf n} to an outcome", start := n, goal := (kind · == .outcome), target := n }

def run (es : Edges) (q : Query) : IO (List N × Nat × TraceEntry) :=
  resolve q.name (candidate es q) (readback es q) levels

def found (t : TraceEntry) : Bool :=
  match t.outcome with
  | .found _ => true
  | _ => false

/-- Both witnesses for every node. -/
def certify (es : Edges) : IO (List (List N × Nat × TraceEntry)) := do
  let mut out := []
  for n in all do
    out := out ++ [← run es (fromLaunch n), ← run es (toOutcome n)]
  return out

end UserFlow.Navigable
