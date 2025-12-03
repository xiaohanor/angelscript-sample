class AIslandEntranceProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent StartLocationComp;

	UPROPERTY(DefaultComponent)
	USceneComponent EndLocationComp;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY(EditAnywhere)
	bool bKillPlayer = true;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 2;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY()
    FVector StartLocation;

	UPROPERTY()
    FVector EndLocation;

	UPROPERTY()
	bool bIsDeactivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = StartLocationComp.GetWorldLocation();
		EndLocation = EndLocationComp.GetWorldLocation();

		MoveAnimation.SetPlayRate(1.0);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if(PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		LaunchProjectile();
	}

	UFUNCTION()
	void LaunchProjectile()
	{
		if (bIsDeactivated)
			return;

		EndLocation = Game::GetPlayer(UsableByPlayer).GetActorLocation();

		// EndLocation = EndLocation - FVector(0,0,3000);

		BP_Activated();
		MoveAnimation.PlayFromStart();
	}
	
	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		Root.SetWorldLocation(Math::Lerp(StartLocation, EndLocation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		BP_OnFinished();
		Root.SetWorldLocation(StartLocation);
		LaunchProjectile();
	}

	UFUNCTION()
	void DeactivateProjectile()
	{
		bIsDeactivated = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnFinished() {}

};