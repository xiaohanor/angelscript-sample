class AMeltdownBossPhaseThreeHydraPortal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent GroundPortal;
	default GroundPortal.SetHiddenInGame(true);

	FHazeTimeLike OpenHydraPortal;
	default OpenHydraPortal.Duration = 1.0;
	default OpenHydraPortal.UseSmoothCurveZeroToOne();

	FVector StartScale;
	FVector EndScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartScale = FVector(0.1,0.1,0.1);
		EndScale = FVector(15.0,15.0,10.0);
		OpenHydraPortal.BindFinished(this, n"OnFinished");
		OpenHydraPortal.BindUpdate(this, n"OnUpdate");
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartPortal()
	{
		RemoveActorDisable(this);
		OpenHydraPortal.Play();
		GroundPortal.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintCallable)
	void ClosePortal()
	{
		OpenHydraPortal.Reverse();

	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		GroundPortal.SetWorldScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
		if(OpenHydraPortal.IsReversed())
		AddActorDisable(this);
		else
		StartHydra();
	}

	UFUNCTION(BlueprintEvent)
	void StartHydra()
	{

	}
};