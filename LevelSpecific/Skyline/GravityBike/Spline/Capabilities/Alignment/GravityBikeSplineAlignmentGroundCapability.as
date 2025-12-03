class UGravityBikeSplineAlignmentGroundCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeSpline::AlignmentTags::GravityBikeSplineAlignment);

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;

	float DistanceBetweenWheels;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);

		DistanceBetweenWheels = GravityBike.FrontWheelComp.WorldLocation.Distance(GravityBike.BackWheelComp.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector GroundNormal;
		if(GravityBikeSpline::Alignment::bUseWheelTrace && TryGetWheelNormal(GroundNormal) && GravityBike.GetForwardSpeed() > 0)
		{
			float Duration = DistanceBetweenWheels / GravityBike.GetForwardSpeed();
			Duration *= GravityBikeSpline::Alignment::GroundWheelAlignmentDurationMultiplier;
			GravityBike.AccBikeUp.AccelerateTo(FQuat::MakeFromZX(GroundNormal, GravityBike.ActorForwardVector), Duration, DeltaTime);
		}
		else
		{
			float Duration = GravityBikeSpline::Alignment::GroundAlignmentDuration;
			GroundNormal = GetGroundNormal(Duration);
			GravityBike.AccBikeUp.AccelerateTo(FQuat::MakeFromZX(GroundNormal, GravityBike.ActorForwardVector), Duration, DeltaTime);
		}
	}

	bool TryGetWheelNormal(FVector&out OutNormal) const
	{
		int WheelTraceCount = 0;
		TArray<AActor> IgnoredActors;
		FHitResult FrontWheelHit = WheelTrace(GravityBike.FrontWheelComp, MoveComp.WorldUp, WheelTraceCount, IgnoredActors);
		FHitResult BackWheelHit = WheelTrace(GravityBike.BackWheelComp, MoveComp.WorldUp, WheelTraceCount, IgnoredActors);

		if(FrontWheelHit.IsValidBlockingHit() && BackWheelHit.IsValidBlockingHit())
		{
			if(FrontWheelHit.Distance > BackWheelHit.Distance)
			{
				OutNormal = BackWheelHit.Normal;
				return false;
			}

			FVector AverageNormal = Math::Lerp(FrontWheelHit.Normal, BackWheelHit.Normal, 0.5);
			OutNormal = AverageNormal.GetSafeNormal();

			FVector ToFront = (FrontWheelHit.Location - BackWheelHit.Location);
			FVector Up = ToFront.CrossProduct(GravityBike.ActorRightVector).GetSafeNormal();
			//OutNormal = Up.GetSafeNormal();

			OutNormal = Math::Lerp(AverageNormal, Up, 0.5);
			OutNormal.Normalize();
			return true;
		}
		else if(FrontWheelHit.IsValidBlockingHit())
		{
			OutNormal = FrontWheelHit.Normal;
			return false;
		}
		else if(BackWheelHit.IsValidBlockingHit())
		{
			OutNormal = BackWheelHit.Normal;
			return false;
		}
		else
		{
			OutNormal = GravityBike.GetGlobalWorldUp();
			return false;
		}
	}

	FHitResult WheelTrace(UGravityBikeWheelComponent WheelComp, FVector WorldUp, int& WheelTraceCount, TArray<AActor>& IgnoredActors) const
	{
		const float Offset = 50;
		WheelTraceCount++;
		const FVector StartLocation = GravityBike.ActorTransform.TransformPosition(WheelComp.RelativeToActorLocation + FVector(0, 0, Offset));
		const float SphereRadius = WheelComp.Radius;

		const FVector EndLocation = GravityBike.ActorTransform.TransformPosition(WheelComp.RelativeToActorLocation);

		if(StartLocation.Equals(EndLocation))
			return FHitResult();

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::WorldGeometry, n"GravityBikeSplineGroundTrace");
		const FHazeTraceShape Sphere = FHazeTraceShape::MakeSphere(SphereRadius);
		Settings.UseShape(Sphere);
		Settings.IgnoreActors(IgnoredActors);
		//Settings.DebugDrawOneFrame();

		const FHitResult Hit = Settings.QueryTraceSingle(StartLocation, EndLocation);

		if(!Hit.IsValidBlockingHit())
			return FHitResult();

		if(Hit.Normal.DotProduct(GravityBike.GetGlobalWorldUp()) < 0)
		{
#if EDITOR
			GetTemporalLog().HitResults(f"Ground;WheelTrace {WheelTraceCount} (Upside down!)", Hit, Settings.Shape);
#endif
			return FHitResult();
		}

		if(Hit.Actor != nullptr)
		{
			auto ImpactResponseComp = UGravityBikeSplineImpactResponseComponent::Get(Hit.Actor);
			if(ImpactResponseComp != nullptr)
			{
				if(!ImpactResponseComp.bAllowBikeToAlign)
				{
					IgnoredActors.Add(Hit.Actor);
					return WheelTrace(WheelComp, WorldUp, WheelTraceCount,IgnoredActors);
				}
			}
		}

#if EDITOR
		GetTemporalLog().HitResults(f"Ground;WheelTrace {WheelTraceCount}", Hit, Settings.Shape);
#endif

		return Hit;
	}

	FVector GetGroundNormal(float& Duration) const
	{
		TArray<AActor> IgnoredActors;
		IgnoredActors.Add(GravityBike);
		FHitResult ForwardHit = ForwardTrace(IgnoredActors);
		if(ForwardHit.bBlockingHit)
		{
			Duration = GravityBikeSpline::Alignment::ForwardAlignmentDuration;
			return ForwardHit.Normal;
		}

		FHitResult GroundHit = GroundTrace(MoveComp.WorldUp, IgnoredActors);
		if(GroundHit.bBlockingHit)
			return GroundHit.Normal;

		GroundHit = GroundTrace(GravityBike.GetGlobalWorldUp(), IgnoredActors);

		if(GroundHit.bBlockingHit)
			return GroundHit.Normal;

		return GravityBike.GetGlobalWorldUp();
	}

	FHitResult ForwardTrace(TArray<AActor>& IgnoredActors) const
	{
		const FVector StartLocation = GravityBike.Sphere.WorldLocation;
		const float SphereRadius = GravityBike.Sphere.SphereRadius - 5;

		const FVector EndLocation = StartLocation + GravityBike.ActorVelocity * (GravityBikeSpline::Alignment::ForwardAlignmentDuration * GravityBikeSpline::Alignment::ForwardTraceDistanceMultiplier);

		if(StartLocation.Equals(EndLocation))
			return FHitResult();

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::WorldGeometry, n"GravityBikeSplineForwardTrace");
		const FHazeTraceShape Sphere = FHazeTraceShape::MakeSphere(SphereRadius);
		Settings.UseShape(Sphere);
		Settings.IgnorePlayers();
		Settings.IgnoreActors(IgnoredActors);

		const FHitResult Hit = Settings.QueryTraceSingle(StartLocation, EndLocation);

#if EDITOR
		GetTemporalLog().HitResults("GravityBikeSplineAlignmentGround ForwardTrace", Hit, Settings.Shape);
#endif

		if(Hit.Normal.DotProduct(GravityBike.GetGlobalWorldUp()) < 0.8)
			return FHitResult();

		if(Hit.Actor != nullptr)
		{
			auto ImpactResponseComp = UGravityBikeSplineImpactResponseComponent::Get(Hit.Actor);
			if(ImpactResponseComp != nullptr)
			{
				if(!ImpactResponseComp.bAllowBikeToAlign)
				{
					IgnoredActors.Add(Hit.Actor);
					return ForwardTrace( IgnoredActors);
				}
			}
		}

		return Hit;
	}

	FHitResult GroundTrace(FVector WorldUp, TArray<AActor>& IgnoredActors) const
	{
		const FVector StartLocation = GravityBike.Sphere.WorldLocation;
		const float SphereRadius = GravityBike.Sphere.SphereRadius;

		const FVector EndLocation = StartLocation - WorldUp * (SphereRadius * GravityBikeSpline::Alignment::GroundTraceDistanceMultiplier);

		if(StartLocation.Equals(EndLocation))
			return FHitResult();

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::WorldGeometry, n"GravityBikeSplineGroundTrace");
		const FHazeTraceShape Sphere = FHazeTraceShape::MakeSphere(SphereRadius);
		Settings.UseShape(Sphere);
		Settings.IgnorePlayers();
		Settings.IgnoreActors(IgnoredActors);

		const FHitResult Hit = Settings.QueryTraceSingle(StartLocation, EndLocation);

#if EDITOR
		GetTemporalLog().HitResults("GravityBikeSplineAlignmentGround GroundTrace", Hit, Settings.Shape);
#endif

		if(Hit.Actor != nullptr)
		{
			auto ImpactResponseComp = UGravityBikeSplineImpactResponseComponent::Get(Hit.Actor);
			if(ImpactResponseComp != nullptr)
			{
				if(!ImpactResponseComp.bAllowBikeToAlign)
				{
					IgnoredActors.Add(Hit.Actor);
					return GroundTrace(WorldUp, IgnoredActors);
				}
			}
		}

		return Hit;
	}

#if EDITOR
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(GravityBike).Page("Alignment");
	}
#endif
}