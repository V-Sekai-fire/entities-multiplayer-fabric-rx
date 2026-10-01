/-!
The reference social-VR client's flow from a launch in the headset, written clean-room from its
observed behaviour. A path ends at an outcome node instead of looping back to the hub, so the flow
is a DAG: the theorems at the end are checked by `decide`, and Navigable.lean certifies every path.
-/

namespace UserFlow

inductive Kind where
  | start | screen | decision | action | outcome
  deriving DecidableEq, Repr

inductive N where
  | launch | splash | sessionCheck | signIn | createAccount | secondFactor | terms | ageGate
  | autoSignIn | comfortSetup | homeLoading | homeWorld | inWorld
  | quickMenu | mainMenu | expressionMenu | locomotion | pickups
  | dashboard | herePanel | camera | micToggle | inventory | emoji | respawn | goHome
  | worldBrowser | avatarBrowser | avatarPage | social | inbox | groups | safety | settings
  | calibrate | store | exitConfirm | signOut
  | worldPage | instanceNew | portalDrop | profile | friendRequest | invite | moderate
  | joinFriend | acceptInvite | acceptFriend | groupJoin | joinInstance | portalEnter
  | worldLoading
  | moved | objectUsed | photoTaken | reacted | audioSet | expressed | respawned | portalPlaced
  | arrived | avatarChanged | requestSent | inviteSent | moderated | friendAdded | safetySet
  | settingsSaved | calibrated | purchased | quit | signedOut
  deriving DecidableEq, Repr

open N

/-- Every node, in an order every edge runs forward along. -/
def all : List N :=
  [launch, splash, sessionCheck, signIn, createAccount, secondFactor, terms, ageGate,
   autoSignIn, comfortSetup, homeLoading, homeWorld, inWorld,
   quickMenu, mainMenu, expressionMenu, locomotion, pickups,
   dashboard, herePanel, camera, micToggle, inventory, emoji, respawn, goHome,
   worldBrowser, avatarBrowser, avatarPage, social, inbox, groups, safety, settings,
   calibrate, store, exitConfirm, signOut,
   worldPage, instanceNew, portalDrop, profile, friendRequest, invite, moderate,
   joinFriend, acceptInvite, acceptFriend, groupJoin, joinInstance, portalEnter,
   worldLoading,
   moved, objectUsed, photoTaken, reacted, audioSet, expressed, respawned, portalPlaced,
   arrived, avatarChanged, requestSent, inviteSent, moderated, friendAdded, safetySet,
   settingsSaved, calibrated, purchased, quit, signedOut]

def ui (s : String) : String := "res://addons/vsk_ui/" ++ s

/-- A node's kind, what the player sees or does there, and the rx scene that covers it today
(empty where nothing does yet). -/
def info : N → Kind × String × String
  | launch => (.start, "The app starts in the headset.", "res://vsk_default/scenes/vsk_startup_scene.tscn")
  | splash => (.screen, "Logo over a loading void, then a photosensitivity and community-rules notice.", ui "vsk_welcome_message.tscn")
  | sessionCheck => (.decision, "Is a saved session still valid?", ui "view_controllers/vsk_ui_view_controller_validating.tscn")
  | signIn => (.screen, "Sign-in: account name or email and password, or a linked store or headset account, typed on the virtual keyboard.", ui "view_controllers/vsk_ui_view_controller_login.tscn")
  | createAccount => (.screen, "New account: the panel hands off to a web page as a link or a QR code.", ui "view_controllers/vsk_ui_view_controller_register.tscn")
  | secondFactor => (.screen, "Authenticator-app or emailed code when two-step sign-in is on.", "")
  | terms => (.screen, "Terms of service and privacy policy, accepted once per version.", "")
  | ageGate => (.screen, "Birth date; a younger account gets restricted defaults.", "")
  | autoSignIn => (.action, "Signed in from the saved session, with no panel.", ui "view_controllers/vsk_ui_view_controller_logging_in.tscn")
  | comfortSetup => (.screen, "First run in the headset: standing or seated, real height, snap or smooth turning.", ui "view_controllers/vsk_ui_view_controller_select_standing_or_seated.tscn")
  | homeLoading => (.screen, "The home world downloads and loads; others' avatars show fallbacks until theirs load.", ui "view_controllers/vsk_ui_view_controller_session_loading.tscn")
  | homeWorld => (.screen, "Spawned in the home world wearing the current avatar, a mirror in reach.", "res://vsk_default/scenes/vsk_main_scene.tscn")
  | inWorld => (.screen, "In an instance: moving, talking, seeing and hearing others.", "res://vsk_default/scenes/vsk_main_scene.tscn")
  | quickMenu => (.screen, "Quick menu from the controller's menu button: a compact panel in front of the player.", "")
  | mainMenu => (.screen, "Main menu: worlds, avatars, social, groups, inbox, safety, settings, store, inventory.", ui "view_controllers/vsk_ui_view_controller_big_menu.tscn")
  | expressionMenu => (.screen, "Radial expression menu: gestures, emotes and the avatar's own toggles.", "")
  | locomotion => (.action, "Moving with the controllers or the world grab: stick movement, snap turns, teleport.", "")
  | pickups => (.action, "Picking up and using a world's objects.", "")
  | dashboard => (.screen, "Dashboard: notifications, friends online, recent and favourite worlds.", "")
  | herePanel => (.screen, "This instance: world details, players, instance type, respawn, go home, rejoin.", "")
  | camera => (.screen, "Photo and stream camera held in the hand.", "")
  | micToggle => (.action, "Microphone muted or unmuted; voice and world volume set.", "")
  | inventory => (.screen, "Inventory: emojis, stickers, prints and bought items.", "")
  | emoji => (.action, "An emoji or sticker thrown into the world.", "")
  | respawn => (.action, "Back to the world's spawn point.", "")
  | goHome => (.action, "Off to the home world.", "")
  | worldBrowser => (.screen, "World rows (featured, popular, active, recent, favourites) and search.", ui "views/vsk_ui_view_map_browser.tscn")
  | avatarBrowser => (.screen, "Avatar rows: favourites, own uploads, recently worn, bought from creators.", ui "views/vsk_ui_view_avatar_browser.tscn")
  | avatarPage => (.screen, "Avatar preview with its performance rating and fallback.", ui "views/vsk_ui_view_avatar_menu.tscn")
  | social => (.screen, "Friends online and offline with their status, and recently met players.", "")
  | inbox => (.screen, "Inbox: invites, invite requests, friend requests and group notices.", "")
  | groups => (.screen, "Groups: membership, announcements and group instances.", "")
  | safety => (.screen, "Safety presets per reputation tier: who shows avatars, voices and effects, with per-player overrides.", "")
  | settings => (.screen, "Settings: audio, graphics, comfort and locomotion, seated play, height, controls.", ui "vsk_settings_menu.tscn")
  | calibrate => (.action, "Full-body tracking calibrated from a reference pose.", "res://addons/xr_rig_calibrator/calibration_orchestrator.gd")
  | store => (.screen, "Store: a supporter subscription and creators' items bought with store currency.", "")
  | exitConfirm => (.screen, "Exit asked from the menu, then confirmed.", "")
  | signOut => (.action, "Signed out; the next launch starts at sign-in.", "")
  | worldPage => (.screen, "World page: description, capacity, live instances, favourite and report.", ui "views/vsk_ui_view_map_menu.tscn")
  | instanceNew => (.screen, "New instance: public, friends of friends, friends, invite, invite plus, group or group public, and a region.", ui "vsk_session_menu.tscn")
  | portalDrop => (.action, "A portal to the instance dropped where others can follow.", "")
  | profile => (.screen, "A profile: bio, status, pronouns, mutual friends, and their world if it is visible.", "")
  | friendRequest => (.action, "A friend request sent.", "")
  | invite => (.action, "An invite here, or a request for one.", "")
  | moderate => (.action, "Mute, block, hide their avatar, or report them.", "")
  | joinFriend => (.action, "Joining a friend whose status allows it.", "")
  | acceptInvite => (.action, "An invite accepted.", "")
  | acceptFriend => (.action, "A friend request accepted.", "")
  | groupJoin => (.action, "Joining a group instance.", "")
  | joinInstance => (.action, "Going to the chosen instance.", ui "vsk_session_menu.tscn")
  | portalEnter => (.action, "Walking into a portal another player dropped.", "")
  | worldLoading => (.screen, "The world downloads and loads.", ui "view_controllers/vsk_ui_view_controller_session_loading.tscn")
  | moved => (.outcome, "Somewhere else in the same world.", "")
  | objectUsed => (.outcome, "The object used.", "")
  | photoTaken => (.outcome, "A photo saved.", "")
  | reacted => (.outcome, "The reaction seen by those nearby.", "")
  | audioSet => (.outcome, "Heard and hearing at the chosen levels.", "")
  | expressed => (.outcome, "The gesture or emote seen by those nearby.", "")
  | respawned => (.outcome, "At the world's spawn point.", "")
  | portalPlaced => (.outcome, "A portal standing for others to follow.", "")
  | arrived => (.outcome, "In the new instance's world.", "")
  | avatarChanged => (.outcome, "Wearing the new avatar; others see it once it loads.", "")
  | requestSent => (.outcome, "The request waiting on them.", "")
  | inviteSent => (.outcome, "The invite waiting on them.", "")
  | moderated => (.outcome, "Their voice, avatar or presence handled.", "")
  | friendAdded => (.outcome, "A new friend in the list.", "")
  | safetySet => (.outcome, "The new safety preset applied.", "")
  | settingsSaved => (.outcome, "The settings kept.", "")
  | calibrated => (.outcome, "The tracked body matches the avatar.", "")
  | purchased => (.outcome, "The purchase in the inventory.", "")
  | quit => (.outcome, "The app closes.", "")
  | signedOut => (.outcome, "Signed out.", "")

def kind (n : N) : Kind := (info n).1

/-- A node's id in snake case, as the GDScript side names it. -/
def nameOf (n : N) : String :=
  let name := ((toString (repr n)).splitOn ".").getLast!
  name.foldl (fun acc c => if c.isUpper then acc ++ "_" ++ String.singleton c.toLower else acc.push c) ""

/-- Each step the player can take: from, to, and what takes them there. -/
def edges : List (N × N × String) :=
  [(launch, splash, "the app opens in the headset"),
   (splash, sessionCheck, "the notice is dismissed"),
   (sessionCheck, autoSignIn, "the saved session is valid"),
   (sessionCheck, signIn, "no valid session"),
   (signIn, createAccount, "no account yet"),
   (signIn, secondFactor, "password accepted, two-step on"),
   (signIn, terms, "password accepted, two-step off"),
   (createAccount, terms, "account made on the web"),
   (secondFactor, terms, "code accepted"),
   (terms, ageGate, "accepted, no birth date on file"),
   (terms, comfortSetup, "accepted, first run in the headset"),
   (terms, homeLoading, "accepted"),
   (ageGate, comfortSetup, "birth date given, first run in the headset"),
   (ageGate, homeLoading, "birth date given"),
   (autoSignIn, homeLoading, "signed in"),
   (comfortSetup, homeLoading, "play mode chosen"),
   (homeLoading, homeWorld, "loaded"),
   (homeWorld, inWorld, "the instance is live"),
   (inWorld, quickMenu, "the menu button"),
   (inWorld, mainMenu, "the menu button held"),
   (inWorld, expressionMenu, "the expression button"),
   (inWorld, locomotion, "a stick, a teleport aim, or both grips"),
   (inWorld, pickups, "a grip on an object"),
   (inWorld, portalEnter, "walking into a portal"),
   (quickMenu, mainMenu, "expand"),
   (quickMenu, dashboard, "the dashboard tab"),
   (quickMenu, herePanel, "the instance tab"),
   (quickMenu, camera, "camera"),
   (quickMenu, micToggle, "mute or volume"),
   (quickMenu, emoji, "emoji"),
   (quickMenu, safety, "safety"),
   (quickMenu, settings, "settings"),
   (quickMenu, exitConfirm, "exit"),
   (mainMenu, inventory, "inventory"),
   (mainMenu, worldBrowser, "worlds"),
   (mainMenu, avatarBrowser, "avatars"),
   (mainMenu, social, "social"),
   (mainMenu, inbox, "inbox"),
   (mainMenu, groups, "groups"),
   (mainMenu, safety, "safety"),
   (mainMenu, settings, "settings"),
   (mainMenu, store, "store"),
   (expressionMenu, expressed, "a gesture, emote or toggle"),
   (locomotion, moved, "the move ends"),
   (pickups, objectUsed, "the object is used"),
   (dashboard, inbox, "a notification"),
   (dashboard, worldPage, "a recent or favourite world"),
   (dashboard, joinFriend, "a friend's join"),
   (herePanel, respawn, "respawn"),
   (herePanel, goHome, "go home"),
   (herePanel, worldPage, "the world's page"),
   (herePanel, profile, "a player in the list"),
   (herePanel, joinInstance, "rejoin"),
   (camera, photoTaken, "the shutter"),
   (micToggle, audioSet, "levels set"),
   (inventory, emoji, "an emoji or sticker"),
   (emoji, reacted, "thrown"),
   (respawn, respawned, "done"),
   (goHome, worldLoading, "the home world is fetched"),
   (worldBrowser, worldPage, "a world"),
   (avatarBrowser, avatarPage, "an avatar"),
   (avatarPage, avatarChanged, "wear"),
   (social, profile, "a friend or player"),
   (inbox, acceptInvite, "accept an invite"),
   (inbox, acceptFriend, "accept a friend request"),
   (groups, groupJoin, "a group instance"),
   (safety, safetySet, "a preset or override"),
   (settings, calibrate, "calibrate tracking"),
   (settings, signOut, "sign out"),
   (settings, settingsSaved, "a change"),
   (calibrate, calibrated, "the pose is held"),
   (store, purchased, "a purchase confirmed"),
   (exitConfirm, quit, "confirmed"),
   (signOut, signedOut, "done"),
   (worldPage, instanceNew, "new instance"),
   (worldPage, joinInstance, "a live instance"),
   (instanceNew, portalDrop, "drop a portal"),
   (instanceNew, joinInstance, "go"),
   (portalDrop, portalPlaced, "placed"),
   (profile, friendRequest, "add friend"),
   (profile, invite, "invite or ask for an invite"),
   (profile, moderate, "mute, block, hide or report"),
   (profile, joinFriend, "join"),
   (friendRequest, requestSent, "sent"),
   (invite, inviteSent, "sent"),
   (moderate, moderated, "done"),
   (joinFriend, worldLoading, "their instance is fetched"),
   (acceptInvite, worldLoading, "the instance is fetched"),
   (acceptFriend, friendAdded, "done"),
   (groupJoin, worldLoading, "the instance is fetched"),
   (joinInstance, worldLoading, "the instance is fetched"),
   (portalEnter, worldLoading, "the portal's instance is fetched"),
   (worldLoading, arrived, "loaded")]

def idx (n : N) : List N → Nat
  | [] => 0
  | m :: ms => if m = n then 0 else idx n ms + 1

def succsOf (es : List (N × N × String)) (n : N) : List N :=
  es.filterMap fun (a, b, _) => if a = n then some b else none

/-- Every edge runs forward along `all`, so the graph has no cycle. -/
def forwardOf (es : List (N × N × String)) : Bool :=
  es.all fun (a, b, _) => idx a all < idx b all

def succs := succsOf edges

set_option maxRecDepth 100000

theorem all_lists_every_node : ∀ n : N, n ∈ all := by
  intro n; cases n <;> decide

theorem all_has_no_repeats : all.Nodup := by decide

theorem edges_run_forward : forwardOf edges = true := by decide +kernel

theorem outcomes_end_paths : all.all (fun n => kind n != .outcome || succs n == []) = true := by decide

theorem only_outcomes_end_paths : all.all (fun n => kind n == .outcome || succs n != []) = true := by decide

theorem launch_is_the_only_start : all.all (fun n => (kind n == .start) == (n == launch)) = true := by decide

/-! Control: the forward check rejects a planted back edge. -/

example : forwardOf (edges ++ [(worldLoading, inWorld, "a planted back edge")]) = false := by decide +kernel


end UserFlow
