class UPinballBossBallPredictionMoveCapability : UPinballBossBallPredictionBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;	// Tick after UPinballPredictionSystemCapability

	UHazeMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		if(HasControl())
			return;
		
		Super::Setup();

		MoveComp = UHazeMovementComponent::Get(BossBall);
		MoveData = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		// If we don't have any crumb data, we don't want to move the player, since then we are modifying the initial data.
		if(!MoveComp.HasAnyDataInCrumbTrail())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!MoveComp.HasAnyDataInCrumbTrail())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BossBall.BlockCapabilities(CapabilityTags::MovementFollow, this);
		BossBall.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossBall.UnblockCapabilities(CapabilityTags::MovementFollow, this);
		BossBall.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		check(!HasControl());

		if(!MoveComp.PrepareMove(MoveData, Proxy.MoveComp.WorldUp))
			return;

		FVector TargetLocation = PredictionComp.GetInterpolatedPredictedLocation();

		// if (Pinball::Prediction::bPredictedBallPlaceOnGround)
		// 	TargetLocation = ValidateGround(TargetLocation);

		MoveData.AddDeltaFromMoveTo(TargetLocation);

		MoveComp.ApplyMove(MoveData);

		MoveComp.OverrideGroundContact(Proxy.MoveComp.GroundContact.ConvertToHitResult(), this);
	}

	FVector ValidateGround(FVector InTargetLocation) const
	{
		FVector TargetLocation = InTargetLocation;
		FHazeTraceSettings Trace;
		Trace.TraceWithMovementComponent(MoveComp);
		//Trace.DebugDrawOneFrame();
		//Trace.UseSphereShape(MoveComp.GetCollisionCapsuleRadius() - 1);

		const float ValidationDistance = APinballBossBall::Radius;
		FVector ValidationEnd = TargetLocation + MoveComp.WorldUp * ValidationDistance;

		if(TargetLocation.Equals(ValidationEnd))
			return TargetLocation;

		FHitResult UpValidationHit = Trace.QueryTraceSingle(
			TargetLocation,
			ValidationEnd,
		);

#if !RELEASE
		TEMPORAL_LOG(PredictionComp).Page("PredictionMove")
			.Sphere("00#Initial;TargetLocation", TargetLocation, APinballBossBall::Radius)
			.Sphere("01#UpValidation;Location", UpValidationHit.Location, APinballBossBall::Radius)
			.HitResults("01#UpValidation;Hit", UpValidationHit, Trace.Shape, Trace.ShapeWorldOffset)
		;
#endif

		if(UpValidationHit.bStartPenetrating)
		{
			// The up validation failed, ignore the component we hit and try again
			Trace.IgnoreComponent(UpValidationHit.Component);
			UpValidationHit = Trace.QueryTraceSingle(
				TargetLocation,
				ValidationEnd,
			);

			// Init trace again to clear the ignored component
			Trace.TraceWithMovementComponent(MoveComp);

#if !RELEASE
			TEMPORAL_LOG(PredictionComp).Page("PredictionMove")
				.Sphere("02#2nd UpValidation;Location", UpValidationHit.Location, APinballBossBall::Radius)
				.HitResults("02#2nd UpValidation;Hit", UpValidationHit, Trace.Shape, Trace.ShapeWorldOffset)
			;
#endif
		}

		if(UpValidationHit.bStartPenetrating)
		{
			// We are still penetrating!
			// Do a ground trace, but use just a line. This should be quite fail proof
			Trace.UseLine();
			const FVector ShapeOffset = MoveComp.WorldUp * APinballBossBall::Radius;

			if(UpValidationHit.Location.Equals(TargetLocation - ShapeOffset))
				return TargetLocation;

			const FHitResult GroundLineHit = Trace.QueryTraceSingle(
				UpValidationHit.Location,
				TargetLocation - ShapeOffset,
			);

#if !RELEASE
			TEMPORAL_LOG(PredictionComp).Page("PredictionMove")
				.Point("03#GroundLineHit;Location", TargetLocation)
				.HitResults("03#GroundLineHit;Hit", GroundLineHit, Trace.Shape, Trace.ShapeWorldOffset)
			;
#endif

			if (GroundLineHit.IsValidBlockingHit() && GroundLineHit.Normal.DotProduct(MoveComp.WorldUp) > 0.5)
			{
				TargetLocation = GroundLineHit.Location + ShapeOffset;
				MoveData.OverrideFinalGroundResult(GroundLineHit, false);
			}
		}
		else
		{
			const FVector GroundTraceStart = UpValidationHit.bBlockingHit ? UpValidationHit.Location : UpValidationHit.TraceEnd;
			
			if(GroundTraceStart.Equals(TargetLocation))
				return TargetLocation;

			const FHitResult GroundShapeHit = Trace.QueryTraceSingle(
				GroundTraceStart,
				TargetLocation,
			);

#if !RELEASE
			TEMPORAL_LOG(PredictionComp).Page("PredictionMove")
				.Sphere("03#GroundShapeHit;Location", TargetLocation, APinballBossBall::Radius)
				.HitResults("03#GroundShapeHit;Hit", GroundShapeHit, Trace.Shape, Trace.ShapeWorldOffset)
			;
#endif

			if (GroundShapeHit.IsValidBlockingHit() && GroundShapeHit.Normal.DotProduct(MoveComp.WorldUp) > 0.5)
			{
				TargetLocation = GroundShapeHit.Location;
				MoveData.OverrideFinalGroundResult(GroundShapeHit, false);
			}
		}

		return TargetLocation;
	}
};