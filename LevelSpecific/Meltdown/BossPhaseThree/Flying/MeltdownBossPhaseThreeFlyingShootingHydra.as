class AMeltdownBossPhaseThreeFlyingShootingHydra : AHazeCharacter
{

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent GroundPortal;
	default GroundPortal.SetHiddenInGame(true);

	FHazeTimeLike OpenHydraPortal;
	default OpenHydraPortal.Duration = 1.0;
	default OpenHydraPortal.UseSmoothCurveZeroToOne();

	FVector StartScale;
	FVector EndScale;

	AHazePlayerCharacter Player;

	FVector TargetLoc;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::GetClosestPlayer(ActorLocation);

		StartScale = FVector(0.1,0.1,0.1);
		EndScale = FVector(15.0,15.0,15.0);
		OpenHydraPortal.BindFinished(this, n"OnFinished");
		OpenHydraPortal.BindUpdate(this, n"OnUpdate");
		AddActorDisable(this);
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

	UFUNCTION(BlueprintCallable)
	void OrientToTarget()
	{
		SetActorTickEnabled(true);
		TargetLoc = Player.ActorLocation;
		FVector Totarget = (TargetLoc - ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		FQuat TargetRot = Totarget.ToOrientationQuat();
		SetActorRotation(TargetRot);
	}

	UFUNCTION(BlueprintCallable)
	void StartPortal()
	{
		RemoveActorDisable(this);
		OpenHydraPortal.Play();
		GroundPortal.SetHiddenInGame(false);
		StartHydra();
	}

	UFUNCTION(BlueprintCallable)
	void ClosePortal()
	{
		OpenHydraPortal.Reverse();

	}

};