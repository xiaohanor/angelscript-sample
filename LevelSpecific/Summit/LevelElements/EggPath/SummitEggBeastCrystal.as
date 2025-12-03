class ASummitEggBeastCrystal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent EndLocationComp;

	UPROPERTY(EditInstanceOnly)
	ASummitEggStoneBeast StoneBeastRef;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	bool bKillPlayer = true;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 0.5;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY()
    FVector StartLocation;

	UPROPERTY()
    FVector EndLocation;

	UPROPERTY()
	bool bIsActive;

	UPROPERTY()
	bool bIsFinished;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = Root.GetWorldLocation();
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
		ShootCrystal();
	}

	UFUNCTION()
	void ShootCrystal()
	{
		if (bIsActive)
			return;

		bIsActive = true;

		if (StoneBeastRef == nullptr)
		{

		}
		else
		{
			StartLocation = StoneBeastRef.MuzzleComp.GetWorldLocation();
		}

		BP_Activated();
		MoveAnimation.PlayFromStart();
	}
	
	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		Root.SetWorldLocation(Math::Lerp(StartLocation, EndLocation, Alpha));
		Root.AddLocalRotation(FRotator(1,1, 1));
	}

	UFUNCTION()
	void OnFinished()
	{
		bIsFinished = true;
		BP_OnFinished();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnFinished() {}

};