event void IslandOverseerPovCameraControllerIntroStartedEvent();
event void IslandOverseerPovCameraControllerIntroEndedEvent();
event void IslandOverseerPovCameraControllerOutroStartedEvent();
event void IslandOverseerPovCameraControllerOutroEndedEvent();

class AIslandOverseerPovCameraController : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	bool bLookAtPlayers = true;
	bool bIntro;
	bool bOutro;
	FVector LookAtLocation;
	FHazeAcceleratedRotator AccRotation;
	FVector IntroFocusLocation;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccRotation.SnapTo(ActorRotation);
		IntroFocusLocation = TListedActors<AIslandOverseerPovIntroFocusPoint>()[0].ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Location = IntroFocusLocation;
		float Duration = 0.5;
		if(bLookAtPlayers)
		{
			FVector MidLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
			FVector Dir = (MidLocation - Location).GetSafeNormal();
			float Distance = Math::Clamp(MidLocation.Distance(Location), 0, 100);
			Location = Location + Dir * Distance;
			Duration = 4;
		}
		
		AccRotation.AccelerateTo((Location - ActorLocation).Rotation(), Duration, DeltaSeconds);
		ActorRotation = AccRotation.Value;
	}
}