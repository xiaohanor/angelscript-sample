class USkylineBallBossRotateSwooshSwingLaserCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);

	int LastChildAlignCount = 0;

	FHazeRuntimeSpline SwooshSpline;
	FHazeAcceleratedFloat AccSpeed;

	FRotator ToStageRot;

	AHazeActor Zoe;
	AHazeActor Mio;
	bool bTargetZoe = true;

	int NumberOfSwings = 0;

	FVector TopLeft; 
	FVector TopRight; 
	FVector DownLeft; 
	FVector DownRight;

	float SplineDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ToStageRot = (BallBoss.OnStageActor.ActorLocation - BallBoss.ActorLocation).ToOrientationRotator();
		FVector SidewaysOffset = ToStageRot.RightVector * 2000.0;
		FVector ForwardOffset = ToStageRot.ForwardVector * 2000.0;
		FVector UpwardsOffset = FVector::UpVector * 1000.0;
		FVector PointInFrontOfBall = BallBoss.ActorLocation + ForwardOffset;
		TopLeft = PointInFrontOfBall - SidewaysOffset + UpwardsOffset; 
		TopRight = PointInFrontOfBall + SidewaysOffset + UpwardsOffset; 
		DownLeft = PointInFrontOfBall - SidewaysOffset - UpwardsOffset; 
		DownRight = PointInFrontOfBall + SidewaysOffset - UpwardsOffset; 
		Zoe = Game::Zoe;
		Mio = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return BallBoss.bSwingLaser;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return NumberOfSwings > BallBoss.NumLaserSwings;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		NumberOfSwings = 0;
		UpdateTarget();
		BallBoss.ResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.bSwingLaser = false;
		BallBoss.ResetTarget();
		BallBoss.BigLaserActor.DeactivateLaser();
	}

	private void UpdateTarget()
	{
		// BallBoss.BigLaserActor.ActivateLaser();
		// TArray<FVector> Points;
		// Points.Add(TopLeft);
		// Points.Add(DownRight);
		// Points.Add(TopRight);
		// Points.Add(DownLeft);
		
		// // Points
		// SwooshSpline.SetPoints(Points);
		// SwooshSpline.SetLooping(true);

		// SwooshSpline.GetClosestLocationToLocation()
		// SplineDistance = 
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SwooshSpline.DrawDebugSpline();
	}
}
