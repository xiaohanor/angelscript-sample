asset SummitTopDownCameraFocusPlayerSheet of UHazeCapabilitySheet
{
	Components.Add(USummitTopDownCameraFocusPlayerComponent);
	AddCapability(n"SummitTopDownCameraFocusPlayerHorizontalLocationUpdateCapability");
	AddCapability(n"SummitTopDownCameraFocusPlayerVerticalLocationUpdateCapability");
}

class ASummitTopDownCameraFocusActor : AHazeActor
{
	default ActorTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitTopDownCameraFocusCapability");

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.WorldScale3D = FVector(5, 5, 5);
#endif

	TPerPlayer<FVector> PlayerLocation;

	UPlayerTeenDragonComponent DragonComp;

	bool bHasBeenActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RequestComp.AddSheetToInitialStopped(SummitTopDownCameraFocusPlayerSheet);

		for(auto Player : Game::Players)
		{
			auto FocusComp = USummitTopDownCameraFocusPlayerComponent::Get(Player);
			FocusComp.FocusActor = this;
		}
	}

	bool TopDownIsActive()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Game::Mio);
		if(DragonComp == nullptr)
			return false;

		return DragonComp.bTopDownMode;
	}

	void SnapToBetweenPlayers()
	{
		FVector TargetLocation;
		for(auto Player : Game::Players)
		{
			TargetLocation = Player.ActorCenterLocation;
			PlayerLocation[Player] = Player.ActorCenterLocation;
		}
		TargetLocation *= 0.5;

		SetActorLocation(TargetLocation);
	}
};