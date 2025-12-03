class UMoonMarketNPCWalkCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;

	UPolymorphResponseComponent PolymorphComp;
	UMoonMarketNPCWalkComponent WalkComp;
	UMoonMarketThunderStruckComponent ThunderComp;
	UHazeMovementComponent MoveComp;
	USweepingMovementData MoveData;

	float CurrentSpeedMultiplier = 1;

	const float SlowdownDistance = 200;

	int NextIdlePointIndex;

	bool bDeactivate = false;

	FVector MoveDeltaThisFrame;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WalkComp = UMoonMarketNPCWalkComponent::Get(Owner);
		PolymorphComp = UPolymorphResponseComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		ThunderComp = UMoonMarketThunderStruckComponent::Get(Owner);

		if(MoveComp != nullptr)
			MoveData = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WalkComp.WalkSpline == nullptr)
			return false;

		if(WalkComp.bIdling)
			return false;

		if(!WalkComp.bActivated)
			return false;

		if(MoveComp == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bDeactivate)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WalkComp.CurrentSplinePosition = WalkComp.WalkSpline.Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
		bDeactivate = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bDeactivate)
		{
			WalkComp.bIdling = true;
			WalkComp.SetNextIdlePoint();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			FHitResult ObstacleHit = TraceForObstacles(DeltaTime);


			if(ObstacleHit.bBlockingHit)
			{
				CurrentSpeedMultiplier = WalkComp.SlowdownCurve.GetFloatValue(1 - Math::Clamp(ObstacleHit.ImpactPoint.DistSquared2D(Owner.ActorLocation) / Math::Square(SlowdownDistance), 0, 1));
			}
			else
			{
				CurrentSpeedMultiplier = Math::FInterpConstantTo(CurrentSpeedMultiplier, 1, DeltaTime, 1);
			}

			float SpeedMult = CurrentSpeedMultiplier;
			if(SpeedMult < 0.5)
				SpeedMult = 0;

			float HorizontalSpeed = WalkComp.WalkSpeed;

			if(PolymorphComp.ShapeshiftComp.IsShapeshiftActive())
			{
				HorizontalSpeed = PolymorphComp.ShapeshiftComp.ShapeData.MoveSpeed;
			}
			else
			{
				if(ThunderComp.WasRainedOnRecently())
				{
					HorizontalSpeed *= 1.5;
				}
			}

			WalkComp.CurrentSplinePosition.Move(HorizontalSpeed * SpeedMult * DeltaTime);
			FVector NewLocation = WalkComp.CurrentSplinePosition.WorldLocation;
			FRotator NewRotation;

			if(WalkComp.NextIdlePoint != nullptr)
			{
				if(WalkComp.NextIdlePoint.WorldLocation.DistSquared2D(WalkComp.CurrentSplinePosition.WorldLocation) < 2500)
					NewRotation = Math::RInterpConstantTo(Owner.ActorRotation, WalkComp.NextIdlePoint.WorldRotation, DeltaTime, 100);
				else
					NewRotation = Math::RInterpConstantTo(Owner.ActorRotation, WalkComp.CurrentSplinePosition.WorldRotation.Rotator(), DeltaTime, 200);


				TOptional<FAlongSplineComponentData> AlongSplineCompData = WalkComp.WalkSpline.Spline.FindNextComponentAlongSpline(UMoonMarketNPCIdleSplinePoint, false, WalkComp.CurrentSplinePosition.CurrentSplineDistance);
				if(AlongSplineCompData.IsSet())
				{
					if(AlongSplineCompData.GetValue().Component != WalkComp.NextIdlePoint)
						bDeactivate = true;
				}
			}
			else
			{
				NewRotation = Math::RInterpConstantTo(Owner.ActorRotation, WalkComp.CurrentSplinePosition.WorldRotation.Rotator(), DeltaTime, 200);
			}

			MoveDeltaThisFrame = NewLocation - Owner.ActorLocation;
			MoveData.AddPendingImpulses();
			MoveData.AddGravityAcceleration();
			MoveData.AddDelta(MoveDeltaThisFrame);
			MoveData.SetRotation(NewRotation);
		}
		else
		{
			if(MoveComp.HasGroundContact())
				MoveData.ApplyCrumbSyncedGroundMovement();
			else
				MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
		//Owner.SetActorLocationAndRotation(NewLocation, NewRotation);
	}

	FHitResult TraceForObstacles(float DeltaTime) const
	{
		TArray<EObjectTypeQuery> TypeQueries;
		TypeQueries.Add(EObjectTypeQuery::Pawn);
		TypeQueries.Add(EObjectTypeQuery::PlayerCharacter);
		FHazeTraceSettings TraceSettings = Trace::InitObjectTypes(TypeQueries);
		TraceSettings.UseSphereShape(50);
		TraceSettings.IgnoreActor(Owner);
		//TraceSettings.DebugDrawOneFrame();

		const FVector Start = Owner.ActorLocation;
		const FVector End = WalkComp.WalkSpline.Spline.GetWorldLocationAtSplineDistance(WalkComp.CurrentSplinePosition.CurrentSplineDistance + 150) + FVector::UpVector * 50;
		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);

		return Hit;
	}
};