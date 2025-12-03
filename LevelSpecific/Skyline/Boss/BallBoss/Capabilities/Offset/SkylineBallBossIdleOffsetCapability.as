class USkylineBallBossIdleOffsetCapability : UHazeCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);
	default CapabilityTags.Add(SkylineBallBossTags::RotationOffset);
	default CapabilityTags.Add(SkylineBallBossTags::RotationOffsetIdle);
	default CapabilityTags.Add(SkylineBallBossTags::BallBossBlockedInCutsceneTag);

	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb; // No crumb! is local, run on both sides, for maximum snappiness

	ASkylineBallBoss BallBoss;

	// Ball boss movement must tick before UGravityBladeGrappleGravityAlignCapability
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	FHazeRuntimeSpline LocationOffsetSpline;
	float SplineOffsetDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		Build8ShapedSpline();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SplineOffsetDistance += DeltaTime * 100.0;
		SplineOffsetDistance = Math::Wrap(SplineOffsetDistance, 0.0, LocationOffsetSpline.Length);
		FVector LocalOffset = LocationOffsetSpline.GetLocationAtDistance(SplineOffsetDistance);

		FVector WorldLocation = BallBoss.ActorQuat.RotateVector(LocalOffset);
		BallBoss.AcceleratedOffsetVector.AccelerateTo(WorldLocation, 2.0, DeltaTime);
		FVector ImpactInLocalSpace = BallBoss.ActorQuat.UnrotateVector(BallBoss.AcceleratedOffsetVector.Value);
		// Debug::DrawDebugLine(BallBoss.ActorLocation, BallBoss.ActorLocation + ImpactInLocalSpace * 2000.0, ColorDebug::Rose, 20.0, 0.0);
		BallBoss.ImpactLocationOffsetComp.SetRelativeLocation(ImpactInLocalSpace);
		
		BallBoss.AcceleratedOffsetQuat.AccelerateTo(FQuat(), 2.0, DeltaTime);
		BallBoss.FakeRootComp.SetRelativeRotation(BallBoss.AcceleratedOffsetQuat.Value);
	}

	private void Build8ShapedSpline()
	{
		const float LemniscateSize = 200.0;
		TArray<FVector> Points;
		Points.Add(FVector(0.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(0.5, 0.0, 0.5) * LemniscateSize);
		LocationOffsetSpline.SetCustomEnterTangentPoint(Points.Last());
		LocationOffsetSpline.SetCustomExitTangentPoint(Points.Last());
		Points.Add(FVector(1.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(0.5, 0.0, -0.5) * LemniscateSize);
		Points.Add(FVector(0.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(0.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(-0.5, 0.0, 0.5) * LemniscateSize);
		Points.Add(FVector(-1.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(-0.5, 0.0, -0.5) * LemniscateSize);
		LocationOffsetSpline.SetPoints(Points);
		LocationOffsetSpline.SetLooping(true);
	}
};