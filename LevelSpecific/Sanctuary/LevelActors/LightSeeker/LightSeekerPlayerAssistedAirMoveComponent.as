class ULightSeekerPlayerAssistedAirMoveComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;

	TArray<ALightSeeker> AwakeLightSeekers;
	FVector CachedClosestPoint;
	
	bool bCalculatedLightSeekerThisFrame = false;
	//UPlayerPerchSettings Settings;

	UPROPERTY(EditAnywhere)
	float AssistingRange = 500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		//Player.Capabili
		MoveComp = UPlayerMovementComponent::Get(Player);
		//Settings = UPlayerPerchSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bCalculatedLightSeekerThisFrame = false;
	}

	bool AllSeekersAreSleeping()
	{
		return AwakeLightSeekers.Num() == 0;
	}

	FVector GetClosestPointOnLightSeekers()
	{
		if (bCalculatedLightSeekerThisFrame)
			return CachedClosestPoint;

		CachedClosestPoint = FVector::ZeroVector;
		bCalculatedLightSeekerThisFrame = true;

		float SmallestDistance = BIG_NUMBER;
		for (int i = 0; i < AwakeLightSeekers.Num(); ++i) 
		{
			ALightSeeker Seeker = AwakeLightSeekers[i];
			FVector SplineLocation = Seeker.RuntimeSpline.GetClosestLocationToLocation(Player.ActorLocation);
			FVector Diff = SplineLocation - Player.ActorLocation;
			if (Diff.Size() < SmallestDistance)
			{
				SmallestDistance = Diff.Size();
				CachedClosestPoint = SplineLocation;
			}
		}

		return CachedClosestPoint;
	}

};