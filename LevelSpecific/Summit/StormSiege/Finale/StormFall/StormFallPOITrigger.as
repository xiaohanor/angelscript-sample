class AStormFallPOITrigger : AActorTrigger
{
	default ActorClasses.Add(AHazePlayerCharacter);

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	float Blend = 1.0;

	UPROPERTY(EditAnywhere)
	float Duration = 3.5;
	float POITime;

	TArray<AHazePlayerCharacter> Players;
	TPerPlayer<UCameraPointOfInterest> POI;

	bool bComplete;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OnActorEnter");
		for (AHazePlayerCharacter Player : Game::Players)
		{
			POI[Player] = Player.CreatePointOfInterest();
			POI[Player].FocusTarget.SetFocusToComponent(TargetActor.RootComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < POITime)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				POI[Player].Apply(this, Blend);
			}
		}	
		else
		{
			if (bComplete)
			{
				bComplete = true;
				for (AHazePlayerCharacter Player : Game::Players)
				{
					Player.ClearPointOfInterestByInstigator(this);
				}				
			}
		}
	}

	UFUNCTION()
	private void OnActorEnter(AHazeActor Actor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		Players.Add(Player);
		POITime = Time::GameTimeSeconds + Duration;
		bComplete = true;
	}
}