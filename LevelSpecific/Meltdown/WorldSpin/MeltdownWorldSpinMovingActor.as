class AMeltdownWorldSpinMovingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsSplineFollowComponent SplineFollow;
	default SplineFollow.NetworkMode = EFauxPhysicsSplineFollowNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = SplineFollow)
	UFauxPhysicsWeightComponent FauxWeightComp;

	UPROPERTY(DefaultComponent, Attach = FauxWeightComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
    UMeltdownWorldSpinFauxPhysicsResponseComponent FauxResponseComp;

	UPROPERTY(EditAnywhere)
	bool bLimitMovementUntilReveal = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bLimitMovementUntilReveal"))
	float ConsiderVisibleDistance = 100;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bLimitMovementUntilReveal"))
	float MaxSplineDistanceUntilReveal = 100;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bLimitMovementUntilReveal"))
	float MovementModifierUntilReveal = 1.0;

	UPROPERTY(EditAnywhere)
	bool bLimitDistanceFromZoe = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bLimitDistanceFromZoe"))
	float MaxDistanceFromZoe = 2500;
	
	private bool bIsRevealed = false;
	private bool bHasSeenAfterReveal = false;

	UPROPERTY(EditAnywhere)
	AMeltdownWorldSpinManager Manager;

	float Spindirection;

	TArray<UStaticMeshComponent> Wheels;

	bool bHasHitConstraint;



	UFUNCTION(BlueprintCallable)
	void ApplyGravity()
	{
		FauxWeightComp.bApplyGravity = true;
	}

	UFUNCTION(BlueprintCallable)
	void DisableGravity()
	{
		FauxWeightComp.bApplyGravity = false;
	}

	UFUNCTION(BlueprintCallable)
	void TriggerReveal()
	{
		bIsRevealed = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Distance = Game::Zoe.GetDistanceTo(this);
		if (Distance < 8000.0)
			SplineFollow.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		else
			SplineFollow.OverrideNetworkSyncRate(EHazeCrumbSyncRate::Standard);

		if (bLimitMovementUntilReveal)
		{
			if (!bHasSeenAfterReveal)
			{
				const bool bMovingForward = FauxWeightComp.GetGravityDir().DotProduct(SplineFollow.SplinePosition.WorldForwardVector) > 0;
				if (bMovingForward)
				{
					FauxWeightComp.MassScale = 1.0 - (SplineFollow.SplinePosition.CurrentSplineDistance / MaxSplineDistanceUntilReveal);
				}
				else
				{
					FauxWeightComp.MassScale = 1.0;
				}

				if (bIsRevealed && SplineFollow.SplinePosition.CurrentSplineDistance <= ConsiderVisibleDistance)
					bHasSeenAfterReveal = true;
				if (bLimitMovementUntilReveal && !bIsRevealed)
					FauxWeightComp.MassScale *= MovementModifierUntilReveal;
			}
			else
			{
				FauxWeightComp.MassScale = 1.0;
			}
		}

		if (bLimitDistanceFromZoe)
		{
			FVector AwayDirection = (SplineFollow.WorldLocation - Game::Zoe.ActorLocation).GetSafeNormal2D();
			const bool bMovingAway = FauxWeightComp.GetGravityDir().DotProduct(AwayDirection) > 0.1;
			if (bMovingAway)
			{
				float ZoeDistance = SplineFollow.WorldLocation.Dist2D(Game::Zoe.ActorLocation);
				if (ZoeDistance > MaxDistanceFromZoe)
				{
					FauxWeightComp.MassScale = 0.0;
				}
			}
		}
	}
};