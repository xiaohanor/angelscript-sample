class AVillageCanalRubberbandActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor RefSpline;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float DesiredPlayerOffset = 200.0;

	UPROPERTY(EditAnywhere)
	float MaxRange = 2000.0;

	UPROPERTY(EditAnywhere)
	float MaxForce = 15000.0;

	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = RefSpline.Spline;
	}

	UFUNCTION()
	void SetActive(bool bActive)
	{
		SetActorTickEnabled(bActive);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!AreBothPlayersSwimming())
			return;

		float MioDist = SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation);
		float ZoeDist = SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation);

		if (Math::IsNearlyEqual(MioDist, ZoeDist, DesiredPlayerOffset))
			return;

		AHazePlayerCharacter BehindPlayer = Game::Zoe;
		float AheadDist = MioDist;
		float BehindDist = ZoeDist;
		if (MioDist < ZoeDist)
		{
			BehindPlayer = Game::Mio;
			AheadDist = ZoeDist;
			BehindDist = MioDist;
		}

		float DistDif = AheadDist - BehindDist;
		float Force = Math::GetMappedRangeValueClamped(FVector2D(0.0, MaxRange), FVector2D(0.0, MaxForce), DistDif);

		FVector Impulse = (SplineComp.GetWorldRotationAtSplineDistance(BehindDist).ForwardVector * Force).ConstrainToPlane(FVector::UpVector);
		BehindPlayer.AddMovementImpulse(Impulse * DeltaTime);

		PrintToScreen("" + BehindPlayer);
	}
	
	bool AreBothPlayersSwimming()
	{
		UPlayerSwimmingComponent MioSwimComp = UPlayerSwimmingComponent::Get(Game::Mio);
		if (MioSwimComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return false;

		UPlayerSwimmingComponent ZoeSwimComp = UPlayerSwimmingComponent::Get(Game::Zoe);
		if (ZoeSwimComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return false;

		return true;
	}
}