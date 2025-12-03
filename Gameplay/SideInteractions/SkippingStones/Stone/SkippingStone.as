enum ESkippingStoneFinishedReason
{
	HitPlayer,
	Splash,
	TimedOut,
};

event void FSkippingStoneFinishedEvent(ASkippingStone SkippingStone, ESkippingStoneFinishedReason Reason, int Bounces);

UCLASS(Abstract)
class ASkippingStone : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect BounceFeedback;

	UPROPERTY()
	FSkippingStoneFinishedEvent OnFinished;

	private AHazePlayerCharacter ThrownBy;

	float PerformedMovementAlpha = 0.0;
	FMovementDelta IterationDelta;

	float ThrowTime = 0;
	private int Bounces = 0;

	const float LIFETIME = 10;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::GetGameTimeSince(ThrowTime) > LIFETIME)
		{
			OnFinished.Broadcast(this, ESkippingStoneFinishedReason::TimedOut, Bounces);
			DestroyActor();
			return;
		}

		FVector Velocity = ActorVelocity;
		FVector Delta = FVector::ZeroVector;

		Acceleration::ApplyAccelerationToVelocity(Velocity, FVector::DownVector * SkippingStones::Gravity, DeltaSeconds, Delta);

		Velocity = Math::VInterpTo(Velocity, FVector::ZeroVector, DeltaSeconds, SkippingStones::Drag);

		Delta += Velocity * DeltaSeconds;

		IterationDelta = FMovementDelta(Delta, Velocity);

		ResolveMovement();

		AddActorWorldRotation(FRotator(0, 1500 * DeltaSeconds, 0));
	}

	void Throw(FVector InThrowVelocity, AHazePlayerCharacter InThrownBy)
	{
		SetActorVelocity(InThrowVelocity);
		
		ThrowTime = Time::GameTimeSeconds;
		ThrownBy = InThrownBy;

		SetActorTickEnabled(true);

		FSkippingStoneOnThrowEventData EventData;
		EventData.Velocity = InThrowVelocity;
		USkippingStoneEventHandler::Trigger_OnThrow(this, EventData);

		USkippingStonesPlayerEventHandler::Trigger_OnThrow(InThrownBy, EventData);
	}

	void ResolveMovement()
	{
		PerformedMovementAlpha = 0;
		int IterationCount = 0;

		while(IterationCount < 5)
		{
			IterationCount++;
			
			FVector DeltaToTrace = IterationDelta.Delta * GetRemainingMovementAlpha();

			if(DeltaToTrace.IsNearlyZero())
				break;

			const FVector EndLocation = ActorLocation + DeltaToTrace;

			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.UseLine();
			TraceSettings.IgnoreActor(ThrownBy);
			FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, EndLocation);

			if(Hit.IsValidBlockingHit())
			{
				HandleImpact(Hit, DeltaToTrace);
				continue;
			}

			if(DeltaToTrace.Z < 0)
			{
				FPlane WaterPlane;
				if(GetWaterPlane(WaterPlane))
				{
					FVector WaterIntersection;
					if(WaterPlane.SegmentPlaneIntersection(ActorLocation, EndLocation, WaterIntersection))
					{
						HandleWaterImpact(WaterIntersection, DeltaToTrace);
						continue;
					}
				}
			}

			ApplyMovement(DeltaToTrace, 1.0);
		}

		SetActorVelocity(IterationDelta.Velocity);
	}

	void HandleImpact(FHitResult Hit, FVector DeltaToTrace)
	{
		if(Hit.Actor.IsA(AHazePlayerCharacter))
			HandlePlayerImpact(Hit);

		ApplyMovement(DeltaToTrace, Hit.Time);

		FSkippingStoneOnImpactEventData EventData;
		EventData.Hit = Hit;
		EventData.Velocity = IterationDelta.Velocity;
		USkippingStoneEventHandler::Trigger_OnImpact(this, EventData);

		IterationDelta = IterationDelta.Bounce(Hit.ImpactNormal, 0.2);

		ForceFeedback::PlayWorldForceFeedback(BounceFeedback, ActorLocation, true, this, 1000, 10000, 1, 2);
	}

	void HandlePlayerImpact(FHitResult Hit)
	{
		check(Hit.Actor.IsA(AHazePlayerCharacter));

		if(HasControl())
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			CrumbHitPlayer(Player);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter HitPlayer)
	{
		FSkippingStoneOnHitPlayerEventData EventData;
		EventData.Player = HitPlayer;
		USkippingStoneEventHandler::Trigger_OnHitPlayer(this, EventData);

		OnFinished.Broadcast(this, ESkippingStoneFinishedReason::HitPlayer, 0);

		HitPlayer.KillPlayer();
	}

	void HandleWaterImpact(FVector WaterIntersection, FVector DeltaToTrace)
	{
		const float HorizontalSpeed = IterationDelta.Velocity.VectorPlaneProject(FVector::UpVector).Size();
		if(HorizontalSpeed < SkippingStones::HorizontalVelocityThreshold)
		{
			Splash(WaterIntersection);
			PerformedMovementAlpha = 1.0;
			return;
		}

		const float Angle = IterationDelta.Velocity.GetAngleDegreesTo(FVector::DownVector);
		if(Angle < 90 - SkippingStones::VerticalAngleThreshold)
		{
			Splash(WaterIntersection);
			PerformedMovementAlpha = 1.0;
			ForceFeedback::PlayWorldForceFeedback(BounceFeedback, ActorLocation, true, this, 1000, 10000, 1, 2);
			return;
		}

		float DistanceToIntersection = ActorLocation.Distance(WaterIntersection);
		float Time = DistanceToIntersection / DeltaToTrace.Size();

		ApplyMovement(DeltaToTrace, Time);

		Bounces++;

		FSkippingStoneOnWaterBounceEventData EventData;
		EventData.Bounces = Bounces;
		EventData.ImpactPoint = WaterIntersection;
		EventData.VerticalVelocity = Math::Abs(IterationDelta.Velocity.DotProduct(FVector::UpVector)) / 80;
		EventData.HorizontalDirection = IterationDelta.Velocity.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		USkippingStoneEventHandler::Trigger_OnWaterBounce(this, EventData);

		IterationDelta = IterationDelta.Bounce(FVector::UpVector, SkippingStones::SkippingStonesVerticalRestitution);

		FMovementDelta VerticalDelta = IterationDelta.GetVerticalPart(FVector::UpVector);
		FMovementDelta HorizontalDelta = IterationDelta.GetHorizontalPart(FVector::UpVector);
		HorizontalDelta *= SkippingStones::SkippingStonesHorizontalRestitution;
		HorizontalDelta = HorizontalDelta.Rotate(FQuat(FVector::UpVector, -SkippingStones::InwardsCurveAngle * HorizontalSpeed / SkippingStones::MaxThrowSpeed));

		IterationDelta = VerticalDelta + HorizontalDelta;
		ForceFeedback::PlayWorldForceFeedback(BounceFeedback, ActorLocation, true, this, 1000, 10000);
	}

	void ApplyMovement(FVector DeltaToTrace, float Alpha)
	{
		SetActorLocation(ActorLocation + DeltaToTrace * Alpha);

		const float FinalAlpha = GetRemainingMovementAlpha() * Alpha;
		PerformedMovementAlpha += FinalAlpha;
	}

	float GetRemainingMovementAlpha() const
	{
		return 1 - PerformedMovementAlpha;
	}

	void Splash(FVector ImpactPoint)
	{
		FSkippingStoneOnWaterSplashEventData EventData;
		EventData.ImpactPoint = ImpactPoint;
		EventData.VerticalVelocity = Math::Abs(IterationDelta.Velocity.DotProduct(FVector::UpVector)) / 200;
		USkippingStoneEventHandler::Trigger_OnWaterSplash(this, EventData);

		OnFinished.Broadcast(this, ESkippingStoneFinishedReason::Splash, Bounces);

		// Pooling is for suckers!
		DestroyActor();
	}

	/**
	 * Find the highest water spline at our current location, and use that height as the water plane height.
	 * @param OutWaterPlane Water Plane at our current location, with the water height as the Z component, and global up normal.
	 * @return True if we are above a water spline, false if not.
	 */
	bool GetWaterPlane(FPlane&out OutWaterPlane) const
	{
		TArray<ASkippingStonesWaterSpline> WaterSplines = TListedActors<ASkippingStonesWaterSpline>().Array;

		TOptional<float> HighestWater;
		for(auto WaterSpline : WaterSplines)
		{
			FTransform ClosestTransform = WaterSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);

			if(HighestWater.IsSet() && ClosestTransform.Location.Z < HighestWater.Value)
			{
				// This spline is lower than a previous valid height
				continue;
			}

			FVector RelativeLocation = ClosestTransform.InverseTransformPositionNoScale(ActorLocation);
			if(RelativeLocation.Y < 0)
			{
				// We are to the left of this spline, meaning we are outside it.
				continue;
			}

			// This is valid water!
			HighestWater = ClosestTransform.Location.Z;
		}

		if(!HighestWater.IsSet())
			return false;

		FVector Location = ActorLocation;
		Location.Z = HighestWater.Value;

		OutWaterPlane = FPlane(Location, FVector::UpVector);
		return true;
	}
};