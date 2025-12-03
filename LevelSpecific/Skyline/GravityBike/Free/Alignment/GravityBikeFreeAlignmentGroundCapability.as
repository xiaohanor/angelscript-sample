class UGravityBikeFreeAlignmentGroundCapability : UHazeCapability
{
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeAlignment);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;

	float DistanceBetweenWheels;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);

		DistanceBetweenWheels = GravityBike.FrontWheelComp.WorldLocation.Distance(GravityBike.BackWheelComp.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GravityBike.HasModifiedAccUpVectorThisFrame())
			return false;

		if(MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GravityBike.HasModifiedAccUpVectorThisFrame())
			return true;
		
		if(MoveComp.IsInAir())
			return true;

		return false;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		GetTemporalLog().Value("Ground;Alignment Ground", IsActive());
	}
#endif

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector GroundNormal;
		if(GravityBikeFree::Alignment::bUseWheelTrace && TryGetWheelNormal(GroundNormal) && MoveComp.GetForwardSpeed() > 0)
		{
			float Duration = DistanceBetweenWheels / MoveComp.GetForwardSpeed();
			Duration *= GravityBikeFree::Alignment::GroundWheelAlignmentDurationMultiplier;
			GravityBike.AccelerateUpTo(GroundNormal, Duration, DeltaTime, this);
		}
		else
		{
			float Duration = GravityBikeFree::Alignment::GroundAlignmentDuration;
			GroundNormal = GetGroundNormal(Duration);
			GravityBike.AccelerateUpTo(GroundNormal, Duration, DeltaTime, this);
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

			FVector AverageNormal = Math::Lerp(GetMostVerticalNormal(FrontWheelHit), GetMostVerticalNormal(BackWheelHit), 0.5);
			OutNormal = AverageNormal.GetSafeNormal();

			FVector ToFront = (FrontWheelHit.Location - BackWheelHit.Location);
			FVector Up = ToFront.CrossProduct(GravityBike.ActorRightVector).GetSafeNormal();
			//OutNormal = Up.GetSafeNormal();

			OutNormal = Math::Lerp(AverageNormal, Up, 0.5);
			OutNormal.Normalize();

#if EDITOR
			GetTemporalLog().DirectionalArrow(f"Ground;Wheel Normal", GravityBike.ActorLocation, OutNormal * 500);
#endif

			return true;
		}
		else if(FrontWheelHit.IsValidBlockingHit())
		{
			OutNormal = GetMostVerticalNormal(FrontWheelHit);
			return false;
		}
		else if(BackWheelHit.IsValidBlockingHit())
		{
			OutNormal = GetMostVerticalNormal(BackWheelHit);
			return false;
		}
		else
		{
			OutNormal = FVector::UpVector;
			return false;
		}
	}

	FHitResult WheelTrace(UGravityBikeWheelComponent WheelComp, FVector WorldUp, int& WheelTraceCount, TArray<AActor>& IgnoredActors) const
	{
		const float UpOffset = 50 + UMovementFloatingSettings::GetSettings(GravityBike).FloatingHeight.Get(GravityBike.Sphere.SphereRadius);
		const float DownOffset = 5;
		WheelTraceCount++;
		const FVector StartLocation = GravityBike.ActorTransform.TransformPosition(WheelComp.RelativeToActorLocation) + FVector::UpVector * UpOffset;
		const float SphereRadius = WheelComp.Radius;

		const FVector EndLocation = GravityBike.ActorTransform.TransformPosition(WheelComp.RelativeToActorLocation) + FVector::DownVector * DownOffset;

		if(StartLocation.Equals(EndLocation))
			return FHitResult();

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::WorldGeometry, n"GravityBikeFreeGroundTrace");
		const FHazeTraceShape Sphere = FHazeTraceShape::MakeSphere(SphereRadius);
		Settings.UseShape(Sphere);
		Settings.IgnoreActors(IgnoredActors);
		//Settings.DebugDrawOneFrame();

		const FHitResult Hit = Settings.QueryTraceSingle(StartLocation, EndLocation);

		if(!Hit.IsValidBlockingHit())
			return FHitResult();

		if(Hit.Normal.DotProduct(FVector::UpVector) < 0)
		{
#if EDITOR
			GetTemporalLog().HitResults(f"Ground;WheelTrace {WheelTraceCount} (Upside down!)", Hit, Settings.Shape);
#endif
			return FHitResult();
		}

		float Angle = Hit.Normal.GetAngleDegreesTo(GravityBike.GetAcceleratedUp());
		if(Angle > GravityBike.Settings.AlignmentMaxAngle)
		{
#if EDITOR
			GetTemporalLog().HitResults(f"Ground;WheelTrace {WheelTraceCount} (Too steep!)", Hit, Settings.Shape);
#endif
			return FHitResult();
		}

		if(Hit.Actor != nullptr)
		{
			auto ImpactResponseComp = UGravityBikeFreeImpactResponseComponent::Get(Hit.Actor);
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
		const FHitResult ForwardHit = ForwardTrace(IgnoredActors);
		if(ForwardHit.IsValidBlockingHit())
		{
			FHitResult RedirectedHit = RedirectedForwardTrace(ForwardHit, IgnoredActors);
			if(RedirectedHit.IsValidBlockingHit())
			{
				GravityBike.ForwardTraceWasRedirectedFrame = Time::FrameNumber;
				const float Alpha = Math::Square(1 - ForwardHit.Time);
				Duration = Math::Lerp(GravityBikeFree::Alignment::ForwardAlignmentDuration, GravityBikeFree::Alignment::ForwardRedirectAlignmentDuration, Alpha);
				const FVector Normal = Math::Lerp(GetMostVerticalNormal(ForwardHit), GetMostVerticalNormal(RedirectedHit), Alpha);
				return Normal.GetSafeNormal();
			}
			else
			{
				Duration = GravityBikeFree::Alignment::ForwardAlignmentDuration;
				return GetMostVerticalNormal(ForwardHit);
			}
		}

		Duration = GravityBikeFree::Alignment::GroundAlignmentDuration;

		int GroundTraceCount = 0;
		FHitResult GroundHit = GroundTrace(MoveComp.WorldUp, GroundTraceCount, IgnoredActors);
		if(GroundHit.IsValidBlockingHit())
			return GetMostVerticalNormal(GroundHit);

		GroundHit = GroundTrace(FVector::UpVector, GroundTraceCount, IgnoredActors);

		if(GroundHit.IsValidBlockingHit())
			return GetMostVerticalNormal(GroundHit);

		return FVector::UpVector;
	}

	FVector GetMostVerticalNormal(FHitResult Hit) const
	{
		if(Hit.Normal.Z > Hit.ImpactNormal.Z)
			return Hit.Normal;
		else
			return Hit.ImpactNormal;
	}

	FHitResult ForwardTrace(TArray<AActor>& IgnoredActors) const
	{
		const FVector StartLocation = GravityBike.Sphere.WorldLocation;

		const FVector EndLocation = StartLocation + GravityBike.ActorVelocity * (GravityBikeFree::Alignment::ForwardAlignmentDuration * GravityBikeFree::Alignment::ForwardTraceDistanceMultiplier);

		if(StartLocation.Equals(EndLocation))
			return FHitResult();

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::ECC_Visibility, n"GravityBikeFreeForwardTrace");
		Settings.UseLine();
		Settings.IgnorePlayers();
		Settings.IgnoreActors(IgnoredActors);

		const FHitResult Hit = Settings.QueryTraceSingle(StartLocation, EndLocation);

		#if EDITOR
		GetTemporalLog().HitResults("Ground;ForwardTrace", Hit, Settings.Shape);
		#endif

		if(Hit.Actor == nullptr)
			return Hit;

		float Angle = Hit.Normal.GetAngleDegreesTo(GravityBike.GetAcceleratedUp());
		//Angle = Math::Max(Angle, Hit.Normal.GetAngleDegreesTo(GravityBike.GetGlobalWorldUp()));
		
#if EDITOR
		GetTemporalLog().DirectionalArrow("Ground;Normal", Hit.Location, Hit.Normal * 500, Color = FLinearColor::Red);
		GetTemporalLog().DirectionalArrow("Ground;Acc Up Vector", Hit.Location, GravityBike.GetAcceleratedUp() * 500, Color = FLinearColor::Blue);
		GetTemporalLog().Value("Ground;Angle", Angle);
		GetTemporalLog().Value("Ground;Alignment Max Angle", GravityBike.Settings.AlignmentMaxAngle);
		GetTemporalLog().Value("Ground;Can Align", Angle <= GravityBike.Settings.AlignmentMaxAngle);
#endif

		if(Angle > GravityBike.Settings.AlignmentMaxAngle)
			return FHitResult();

		if(Hit.Actor != nullptr)
		{
			auto ImpactResponseComp = UGravityBikeFreeImpactResponseComponent::Get(Hit.Actor);
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

	FHitResult RedirectedForwardTrace(FHitResult PreviousForwardTrace, TArray<AActor>& IgnoredActors) const
	{
		const FVector StartLocation = PreviousForwardTrace.Location;

		FVector RedirectedVelocity = GravityBike.ActorVelocity.VectorPlaneProject(PreviousForwardTrace.Normal);
		const float Magnitude = GravityBike.ActorVelocity.Size() * (GravityBikeFree::Alignment::ForwardAlignmentDuration * GravityBikeFree::Alignment::ForwardTraceDistanceMultiplier) * (1.0 - PreviousForwardTrace.Time);
		RedirectedVelocity = RedirectedVelocity.GetSafeNormal() * Magnitude;

		const FVector EndLocation = StartLocation + RedirectedVelocity;

		if(StartLocation.Equals(EndLocation))
			return FHitResult();

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::ECC_Visibility, n"GravityBikeFreeRedirectedForwardTrace");
		Settings.UseLine();
		Settings.IgnorePlayers();
		Settings.IgnoreActors(IgnoredActors);

		const FHitResult Hit = Settings.QueryTraceSingle(StartLocation, EndLocation);

#if EDITOR
		GetTemporalLog().HitResults("Ground;RedirectedForwardTrace", Hit, Settings.Shape);
#endif

		float Angle = Hit.Normal.GetAngleDegreesTo(GravityBike.GetAcceleratedUp());
		Angle = Math::Max(Angle, Hit.Normal.GetAngleDegreesTo(FVector::UpVector));
		if(Angle > GravityBike.Settings.AlignmentMaxAngle)
			return FHitResult();

		if(Hit.Actor != nullptr)
		{
			auto ImpactResponseComp = UGravityBikeFreeImpactResponseComponent::Get(Hit.Actor);
			if(ImpactResponseComp != nullptr)
			{
				if(!ImpactResponseComp.bAllowBikeToAlign)
				{
					IgnoredActors.Add(Hit.Actor);
					return RedirectedForwardTrace(PreviousForwardTrace, IgnoredActors);
				}
			}
		}

		return Hit;
	}

	FHitResult GroundTrace(FVector WorldUp, int& GroundTraceCount, TArray<AActor>& IgnoredActors) const
	{
		GroundTraceCount++;
		const FVector StartLocation = GravityBike.Sphere.WorldLocation;
		const float SphereRadius = GravityBike.Sphere.SphereRadius;

		const FVector EndLocation = StartLocation - WorldUp * (SphereRadius * GravityBikeFree::Alignment::GroundTraceDistanceMultiplier);

		if(StartLocation.Equals(EndLocation))
			return FHitResult();

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::ECC_Visibility, n"GravityBikeFreeGroundTrace");
		const FHazeTraceShape Sphere = FHazeTraceShape::MakeSphere(SphereRadius);
		Settings.UseShape(Sphere);
		Settings.IgnorePlayers();
		Settings.IgnoreActors(IgnoredActors);

		const FHitResult Hit = Settings.QueryTraceSingle(StartLocation, EndLocation);

		if(Hit.Normal.DotProduct(FVector::UpVector) < 0)
		{
			#if EDITOR
			GetTemporalLog().HitResults(f"Ground;GroundTrace {GroundTraceCount} (Upside down!)", Hit, Settings.Shape);
			#endif
			return FHitResult();
		}

		float Angle = Hit.Normal.GetAngleDegreesTo(GravityBike.GetAcceleratedUp());
		if(Angle > GravityBike.Settings.AlignmentMaxAngle)
		{
			#if EDITOR
			GetTemporalLog().HitResults(f"Ground;GroundTrace {GroundTraceCount} (Too steep!)", Hit, Settings.Shape);
			#endif
			return FHitResult();
		}

		if(Hit.Actor != nullptr)
		{
			auto ImpactResponseComp = UGravityBikeFreeImpactResponseComponent::Get(Hit.Actor);
			if(ImpactResponseComp != nullptr)
			{
				if(!ImpactResponseComp.bAllowBikeToAlign)
				{
					IgnoredActors.Add(Hit.Actor);
					return GroundTrace(WorldUp, GroundTraceCount,IgnoredActors);
				}
			}
		}

#if EDITOR
		GetTemporalLog().HitResults(f"Ground;GroundTrace {GroundTraceCount}", Hit, Settings.Shape);
#endif

		return Hit;
	}

#if EDITOR
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(GravityBike).Page("Alignment");
	}
#endif
}