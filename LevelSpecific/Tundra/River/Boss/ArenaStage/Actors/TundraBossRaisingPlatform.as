class ATundraBossRaisingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	FHazeTimeLike MovePlatformTimelike;
	default MovePlatformTimelike.UseSmoothCurveZeroToOne();
	default MovePlatformTimelike.Duration = 1;

	FVector StartingLoc;

	bool bHasEverBeenActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlatformTimelike.BindUpdate(this, n"MovePlatformTimelikeUpdate");
		MovePlatformTimelike.SetPlayRate(1.0 / 2.0);
		StartingLoc = ActorLocation;
	}

	UFUNCTION()
	private void MovePlatformTimelikeUpdate(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(StartingLoc, StartingLoc + FVector(0, 0, 1000), CurrentValue));
	}

	void RaisePlatform()
	{
		MovePlatformTimelike.PlayFromStart();
		ActivateBlockers(true);
		bHasEverBeenActivated = true;
	}

	void LowerPlatform()
	{
		MovePlatformTimelike.ReverseFromEnd();
		ActivateBlockers(false);		
	}

	void ActivateBlockers(bool bActivate)
	{
		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for(auto Actor : Actors)
		{
			ATundraBossKillingBlockers Blocker = Cast<ATundraBossKillingBlockers>(Actor);
			if(Blocker == nullptr)
				continue;

			Blocker.ActivateBlockers(bActivate);
		}
	}
};