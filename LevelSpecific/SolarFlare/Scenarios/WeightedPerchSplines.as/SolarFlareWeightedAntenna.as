class ASolarFlareWeightedAntenna : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent AxisComp;

	UPROPERTY(DefaultComponent, Attach = AxisComp)
	UStaticMeshComponent MeshCompLeft;

	UPROPERTY(DefaultComponent, Attach = AxisComp)
	UStaticMeshComponent MeshCompRight;

	UPROPERTY(EditAnywhere)
	APerchSpline PerchSplineLeft;

	UPROPERTY(EditAnywhere)
	APerchSpline PerchSplineRight;

	/** How much the player weights down the antenna while on it */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerWeightForce = 150.0;

	/** At which angle the player will fall off the antenna */
	UPROPERTY(EditAnywhere, Category = "Fall Off")
	float PlayerFallOffAngle = 50.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float WalkableRegainThreshold = 20.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SpringStrengthWithOne = 0.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SpringStrengthWithTwo = 5.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SpringStrengthWithNone = 5.0;

	TArray<AHazePlayerCharacter> PlayersOnAntenna;
	TArray<UStaticMeshComponent> MeshComps;

	bool bPlayersCanBeOn = true;

 	const float PlayerFallOffImpulse = 400.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchSplineLeft.AttachToComponent(AxisComp, NAME_None, EAttachmentRule::KeepWorld);
		PerchSplineRight.AttachToComponent(AxisComp, NAME_None, EAttachmentRule::KeepWorld);

		PerchSplineLeft.OnPlayerLandedOnSpline.AddUFunction(this, n"OnPlayerLandedOnPerch");
		PerchSplineLeft.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerchingEvent");
		PerchSplineLeft.OnPlayerJumpedOnSpline.AddUFunction(this, n"OnPlayerJumpedOnPerch");

		PerchSplineRight.OnPlayerLandedOnSpline.AddUFunction(this, n"OnPlayerLandedOnPerch");
		PerchSplineRight.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerchingEvent");
		PerchSplineRight.OnPlayerJumpedOnSpline.AddUFunction(this, n"OnPlayerJumpedOnPerch");

		PerchSplineLeft.MaximumHorizontalJumpToAngle = 30.0;
		PerchSplineRight.MaximumHorizontalJumpToAngle = 30.0;
		PerchSplineLeft.ActivationRange = 500.0;
		PerchSplineRight.ActivationRange = 500.0;

		GetComponentsByClass(MeshComps);

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.RemoveTag(n"Walkable");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : PlayersOnAntenna)
		{
			FVector WeightForce = -AxisComp.UpVector * PlayerWeightForce;
			FauxPhysics::ApplyFauxForceToActorAt(this, Player.ActorLocation, WeightForce);
		}

		float TiltAngle = AxisComp.UpVector.GetAngleDegreesTo(ActorUpVector);
		if(bPlayersCanBeOn
		&& TiltAngle > PlayerFallOffAngle)
			MakePlayersFallOff();
		else if(!bPlayersCanBeOn
		&& TiltAngle < (PlayerFallOffAngle - WalkableRegainThreshold))
			MakeWalkable();
	}

	private void MakePlayersFallOff()
	{
		PerchSplineLeft.AddActorDisable(this);
		PerchSplineRight.AddActorDisable(this);

		for(auto Player : PlayersOnAntenna)
		{
			FVector DirToPlayer = (Player.ActorLocation - ActorLocation).GetSafeNormal();
			FVector ImpulseDirection = ActorRightVector;

			if(DirToPlayer.DotProduct(ActorRightVector) < 0)
				ImpulseDirection *= -1;

			FVector Impulse = ImpulseDirection * PlayerFallOffImpulse;
			Player.AddMovementImpulse(Impulse);
		}

		bPlayersCanBeOn = false;
	}

	private void MakeWalkable()
	{
		PerchSplineLeft.RemoveActorDisable(this);
		PerchSplineRight.RemoveActorDisable(this);

		bPlayersCanBeOn = true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerLandedOnPerch(AHazePlayerCharacter Player)
	{
		PlayersOnAntenna.AddUnique(Player);
		AdjustSpringStrength();

		Print(f"{Player} landed on perch");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerStoppedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent PerchPoint)
	{
		PlayersOnAntenna.RemoveSingleSwap(Player);
		AdjustSpringStrength();

		Print(f"{Player} left perch");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerJumpedOnPerch(AHazePlayerCharacter Player)
	{
		PlayersOnAntenna.RemoveSingleSwap(Player);
		AdjustSpringStrength();

		Print(f"{Player} jumped while on perch");
	}

	private void AdjustSpringStrength()
	{
		if(PlayersOnAntenna.Num() == 0)
			AxisComp.SpringStrength = SpringStrengthWithNone;
		else if (PlayersOnAntenna.Num() == 1)
			AxisComp.SpringStrength = SpringStrengthWithOne;
		else if (PlayersOnAntenna.Num() == 2)
			AxisComp.SpringStrength = SpringStrengthWithTwo;
	} 
}