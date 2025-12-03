class ATundra_IcePalace_FairyFlyIntoLockAnchor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(EditInstanceOnly)
	ALevelSequenceActor AnchorLevelSequenceActor;

	UPROPERTY(EditInstanceOnly)
	AHazeActor TargetLocation;

	FHazeTimeLike FlyToLockTimelike;
	default FlyToLockTimelike.Duration = 1.0;

	FVector StartingLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlyToLockTimelike.BindUpdate(this, n"FlyToLockTimelikeUpdate");
		AnchorLevelSequenceActor.AttachToComponent(Root);
		FlyToLockTimelike.SetPlayRate(1.0 / 1.3);
	}

	UFUNCTION()
	void StartLerpingToLock(FVector StartingLoc)
	{
		StartingLocation = StartingLoc;
		FlyToLockTimelike.PlayFromStart();
	}
	
	UFUNCTION()
	private void FlyToLockTimelikeUpdate(float CurrentValue)
	{
		FVector NewTargetLoc;
		float NewY = Math::Lerp(StartingLocation.Y, TargetLocation.ActorLocation.Y, Math::Clamp(CurrentValue * 2, 0, 1));
		NewTargetLoc = Math::Lerp(StartingLocation, TargetLocation.ActorLocation, CurrentValue);
		NewTargetLoc.Y = NewY;
		
		SetActorLocation(NewTargetLoc);
	}
};