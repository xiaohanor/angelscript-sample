event void FSummitRaftPlayerLaunchZoneLaunchFinishedEvent(AHazePlayerCharacter LaunchedPlayer);
event void FSummitRaftPlayerLaunchZoneLaunchStartedEvent(AHazePlayerCharacter LaunchedPlayer);

class ASummitRaftPlayerLaunchZone : APlayerTrigger
{
	TPerPlayer<bool> PlayersInZone;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USummitRaftPlayerLaunchZoneComponent LaunchZoneComp;

	UPROPERTY()
	FSummitRaftPlayerLaunchZoneLaunchFinishedEvent OnPlayerLaunchFinished;

	UPROPERTY()
	FSummitRaftPlayerLaunchZoneLaunchStartedEvent OnPlayerLaunchStarted;

	UPROPERTY(EditAnywhere)
	float VisualizedTrajectoryLength = 5000;

	default Shape::SetVolumeBrushColor(this, FLinearColor::LucBlue);
	default BrushComponent.LineThickness = 6.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}
	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		// Print(f"Player Entered zone:{Player}", 5);
		PlayersInZone[Player] = true;
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if (!LaunchZoneComp.LaunchedPlayers[Player])
		{
			LaunchZoneComp.ForceLaunch(Player);
		}
		PlayersInZone[Player] = false;
	}
};
