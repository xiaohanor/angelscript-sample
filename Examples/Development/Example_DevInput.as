// DevInput can be bound from any actor or object
UCLASS(Abstract)
class AExampleDevInputActor : AHazeActor
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Struct containing the data and, well, info about the input entry
		FHazeDevInputInfo Info;

		// This is the name of the input being shown in the menu
		// Without it, you'll get the name "None"
		Info.Name = n"ExampleCallback";

		// Category is optional. With no category it will be placed in the "No Category"-category
		Info.Category = n"Examples";

		// Callback function called when entry is triggered
		Info.OnTriggered.BindUFunction(this, n"HandleDevInput");

		// Adding some keys.
		Info.AddKey(EKeys::K);
		Info.AddKey(FKey(n"+")); // Some keys dont exist in EKeys
		Info.AddKey(EKeys::Gamepad_FaceButton_Right);

		// You can also add actions, bound in the project settings
		Info.AddAction(ActionNames::MovementJump);

		// Registering for both players, making in show up in both of their menus
		for(auto Player : Game::Players)
			Player.RegisterDevInput(Info);
	}

	UFUNCTION()
	void HandleDevInput()
	{
	}
}

// Additionally, you can create "handlers" if you want to split up the functions a bit
class UExampleDevInput : UHazeDevInputHandler
{
	// These are the same as the FHazeDevInputInfo struct
	default SetName(n"ExampleHandler");
	default SetCategory(n"Examples");
	default AddKey(EKeys::Add);
	default AddKey(FKey(n"+"));
	default AddKey(EKeys::Gamepad_DPad_Up);

	// Setup() is called when the handler is added to the player
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		// Player can be reached as a property
		auto MoveComp = UHazeMovementComponent::Get(PlayerOwner);
	}

	// Trigger() is called when the entry is triggered from the menu
	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		PlayerOwner.DestroyActor();
	}

	// Determines when the dev input can be used by the user. Returning false means the dev input will not be available.
	UFUNCTION(BlueprintOverride)
	bool CanBeTriggered()
	{
		// return true;
		return false;
	}
}