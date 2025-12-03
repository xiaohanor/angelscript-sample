class UGravityBikeSplineAlignmentAirCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeSpline::AlignmentTags::GravityBikeSplineAlignment);

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(GravityBike);
		const FHitResult Hit = TraceAhead(IgnoreActors);

		if(Hit.bBlockingHit)
		{
#if EDITOR
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			TemporalLog.Value("Alignment Air", "Trace hit something, fast alignment towards GlobalWorldUp");
#endif
			GravityBike.AccBikeUp.AccelerateTo(FQuat::MakeFromZX(GravityBike.GetGlobalWorldUp(), GravityBike.ActorForwardVector), GravityBikeSpline::Alignment::LandingAlignmentDuration, DeltaTime);
		}
		else if(GravityBike.ActorVelocity.VectorPlaneProject(GravityBike.GetGlobalWorldUp()).Size() > 1000)
		{
#if EDITOR
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			TemporalLog.Value("Alignment Air", "Moving horizontally, align slowly with velocity direction");
#endif

			FVector VerticalVelocity = GravityBike.ActorVelocity.ProjectOnToNormal(GravityBike.GetGlobalWorldUp());
			const FVector HorizontalVelocity = GravityBike.ActorVelocity - VerticalVelocity;

			// If moving down, don't align fully because it will be too steep
			if(VerticalVelocity.DotProduct(GravityBike.GetGlobalWorldUp()) < 0)
				VerticalVelocity *= 0.5;

			const FVector Velocity = HorizontalVelocity + VerticalVelocity;

			const FQuat Rotation = FQuat::MakeFromXZ(Velocity, GravityBike.GetGlobalWorldUp());
			GravityBike.AccBikeUp.AccelerateTo(Rotation, GravityBikeSpline::Alignment::AirAlignmentDuration, DeltaTime);
		}
		else
		{
#if EDITOR
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			TemporalLog.Value("Alignment Air", "No hit, barely moving, very slow alignment with WorldUp and ActorForward");
#endif

			const FQuat Rotation = FQuat::MakeFromZX(GravityBike.GetGlobalWorldUp(), GravityBike.ActorForwardVector);
			GravityBike.AccBikeUp.AccelerateTo(Rotation, GravityBikeSpline::Alignment::AirAlignmentDuration, DeltaTime);
		}
	}

	FHitResult TraceAhead(TArray<AActor>& IgnoredActors)
	{
		const FVector StartLocation = GravityBike.Sphere.WorldLocation;
		const float SphereRadius = GravityBike.Sphere.SphereRadius - 4;

		const FVector EndLocation = StartLocation + MoveComp.Velocity * (GravityBikeSpline::Alignment::LandingAlignmentDuration * GravityBikeSpline::Alignment::LandingAlignmentTraceDistanceMultiplier);

		if(StartLocation.Equals(EndLocation))
			return FHitResult();

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::WorldGeometry, n"GravityBikeFreeAirTrace");
		const FHazeTraceShape Sphere = FHazeTraceShape::MakeSphere(SphereRadius);
		Settings.UseShape(Sphere);
		Settings.IgnorePlayers();
		Settings.IgnoreActors(IgnoredActors);

		const FHitResult Hit = Settings.QueryTraceSingle(StartLocation, EndLocation);

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(GravityBike);
		TemporalLog.HitResults("GravityBikeSplineAlignmentAir TraceAhead", Hit, Settings.Shape);
#endif

		if(Hit.ImpactNormal.DotProduct(GravityBike.GetGlobalWorldUp()) < 0.9)
			return FHitResult();

		if(Hit.Actor != nullptr)
		{
			auto ImpactResponseComp = UGravityBikeSplineImpactResponseComponent::Get(Hit.Actor);
			if(ImpactResponseComp != nullptr)
			{
				if(!ImpactResponseComp.bAllowBikeToAlign)
				{
					IgnoredActors.Add(Hit.Actor);
					return TraceAhead(IgnoredActors);
				}
			}
		}

		return Hit;
	}
};