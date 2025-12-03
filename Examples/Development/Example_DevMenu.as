// A standard dev entry widget
// This MUST be implemented as a WBP, for adding widgets.

// !!! HOW TO ADD
// Either add default devmenus in,
//	Project Settings -> Hazelight/Development -> Default Dev Menus
// or, during runtime with
//	through Player.RequestTransientDevMenu()

// Simple UMG devmenu
UCLASS(Abstract)
class UExampleDevMenu : UHazeDevMenuEntryWidget
{
	// Bound in WBP
	UPROPERTY(Meta = (BindWidget))
	UTextBlock DebugText;

	// Bound in WBP
	UPROPERTY(Meta = (BindWidget))
	UButton DebugButton;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geometry, float DeltaTime)
	{
		// GetDebugWorld() or simply DebugWorld will give you the world this widget is working with
		// If you add your menu as global, GetDebugWorld() will return nullptr

		// GetDebugActor() will give you the currently selected actor in the DevMenu
		// 	or nullptr if none is selected
		DebugText.SetText(FText::FromString(f"I'm in world {GetDebugWorld()}, debugging {GetDebugActor()}"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDebugActorChanged(AActor NewActor)
	{
		// Called when the user selects a new debug actor in the DevMenu
	}
}

// OR, if you're feeling frisky, you can create an immediate mode devmenu
// These menus don't need a WBP version, rather they are populated in runtime through function calls (IE immediate mode)
class UExampleImmediateDevMenu : UHazeDevMenuEntryImmediateWidget
{
	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geometry, float DeltaTime)
	{
		auto Section = Drawer.Begin();
		Section.Text("Yo");

		// For more info on immediate mode, see Example_Immediate.as
	}
}

// Examples for requesting dev menus in runtime
class AExampleDevMenuRequester : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Scene;

	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Adding a widget devmenu (either UHazeDevMenuEntryWidget or UHazeDevMenuEntryImmediateWidget)
		// Add a widget with Win+.
		DevMenu::RequestTransientDevMenu(n"Yo", "🎗", UExampleImmediateDevMenu);

		// OR, you can add a direct immediate mode menu, returning a drawer to said menu
		Drawer = DevMenu::RequestImmediateDevMenu(n"Yo Immediate", "🎨");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		DebugDrawImmediate();
	}

	void DebugDrawImmediate()
	{
		// ALWAYS make sure to check if the drawer is visible before doing anything.
		// Otherwise you will get an angelscript exception
		if (!Drawer.IsVisible())
			return;

		// DevMenu selected actor
		if (Drawer.DebugActor != this)
			return;

		// Begin drawing
		auto Section = Drawer.Begin();
		Section.Text(f"My name is {this}");

		if (Section.Button("Kill me"))
			DestroyActor();

		// For more info on immediate mode, see Example_Immediate.as
	}
}