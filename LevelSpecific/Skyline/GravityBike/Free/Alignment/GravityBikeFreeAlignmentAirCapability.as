class UGravityBikeFreeAlignmentAirCapability : UHazeCapability
{
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeAlignment);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;
	
	UGravityBikeFreeCameraDataComponent CameraDataComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);

		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(GravityBike.GetDriver());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GravityBike.HasModifiedAccUpVectorThisFrame())
			return false;

		if(!MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GravityBike.HasModifiedAccUpVectorThisFrame())
			return true;

		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraDataComp.ApproachingGround = FHitResult();
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		GetTemporalLog().Value("Air;Alignment Air", IsActive());
	}
	#endif

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(GravityBike);
		const FHitResult Hit = TraceAhead(IgnoreActors);
		CameraDataComp.ApproachingGround = Hit;

		if(Hit.IsValidBlockingHit() && GravityBikeFree::Alignment::bAlignWithApproachingGround)
		{
#if !RELEASE
			GetTemporalLog().DirectionalArrow("Air;AlignWithApproachingGround", Hit.ImpactPoint, Hit.Normal * 500);
#endif

			// Go towards ground normal
			GravityBike.AccelerateUpTo(
				Hit.Normal,
				GravityBikeFree::Alignment::LandingAlignmentDuration,
				DeltaTime,
				this
			);
		}
		else
		{
			// Go towards global up
			GravityBike.AccelerateUpTo(
				FVector::UpVector,
				GravityBike.ActorVelocity.VectorPlaneProject(FVector::UpVector).GetSafeNormal(),
				GravityBikeFree::Alignment::AirAlignmentDuration,
				DeltaTime,
				this
			);
		}
	}

	FHitResult TraceAhead(TArray<AActor>& IgnoredActors) const
	{
		const FVector StartLocation = GravityBike.Sphere.WorldLocation;
		const float SphereRadius = GravityBike.Sphere.SphereRadius - 4;

		const FVector EndLocation = StartLocation + MoveComp.Velocity * (GravityBikeFree::Alignment::LandingAlignmentDuration * GravityBikeFree::Alignment::LandingAlignmentTraceDistanceMultiplier);

		if(StartLocation.Equals(EndLocation))
			return FHitResult();

		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::ECC_Visibility, n"GravityBikeFreeAirTrace");
		const FHazeTraceShape Sphere = FHazeTraceShape::MakeSphere(SphereRadius);
		Settings.UseShape(Sphere);
		Settings.IgnorePlayers();
		Settings.IgnoreActors(IgnoredActors);

		const FHitResult Hit = Settings.QueryTraceSingle(StartLocation, EndLocation);

#if !RELEASE
		GetTemporalLog().HitResults("Air;TraceAhead", Hit, Settings.Shape);
#endif

		const float Angle = Hit.Normal.GetAngleDegreesTo(GravityBike.GetAcceleratedUp());
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
					return TraceAhead(IgnoredActors);
				}
			}
		}

		return Hit;
	}

#if !RELEASE
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(GravityBike).Page("Alignment");
	}
#endif
}