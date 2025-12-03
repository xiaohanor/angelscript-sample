// trivia: ♾️ infinity symbol has a name

struct FSkylineBallBossPositionActionLemniscateData
{
	float DashDuration = 5.0;
	float StayDuration = 7.0;

	float LemniscateLoopDuration = 3.5;

	ASkylineBallBossLocationNode DashNodeTarget = nullptr;
}

class USkylineBallBossPositionActionLemniscateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Position);
	
	default TickGroup = EHazeTickGroup::LastMovement;

	FSkylineBallBossPositionActionLemniscateData ActivationParams;
	ASkylineBallBoss BallBoss;
	USkylineBallBossActionsComponent BossComp;
	FHazeAcceleratedVector AccLocation;

	FHazeRuntimeSpline Spline;
	float SplineDistanceAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
		Build8ShapedSpline();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossPositionActionLemniscateData& Params) const
	{
		if (BallBoss.FreezeLocationRequesters.Num() > 0)
			return false;
		if (BossComp.PositionActionQueue.Start(this, Params))
		{
			ASkylineBallBossLocationNode NextLocation = SelectNextLocation();
			if (NextLocation == nullptr)
			{
				BossComp.PositionActionQueue.Finish(this);
				return false;
			}
			Params.DashNodeTarget = NextLocation;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.FreezeLocationRequesters.Num() > 0)
			return true;
		if (ActiveDuration > GetTotalDuration())
			return true;
		if (!BossComp.PositionActionQueue.IsActive(this))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossPositionActionLemniscateData Params)
	{
		ActivationParams = Params;
		AccLocation.SnapTo(BallBoss.ActorLocation);
		SplineDistanceAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.PositionActionQueue.Finish(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (BallBoss.bIsInTearOffPositioning)
			return;
		
		FVector TargetLocation = BallBoss.ActorLocation;
		if (ActivationParams.DashNodeTarget != nullptr)
			TargetLocation = ActivationParams.DashNodeTarget.ActorLocation;

		FVector LemniscateOffset = Spline.GetLocationAtDistance(SplineDistanceAlpha * Spline.Length);
		TargetLocation += LemniscateOffset;

		if (SkylineBallBossDevToggles::DrawLocationTarget.IsEnabled())
			Debug::DrawDebugSphere(TargetLocation, 20.0, 12, ColorDebug::Magenta, 3.0, 1.0);
		
		SplineDistanceAlpha += DeltaTime / ActivationParams.LemniscateLoopDuration;
		if (SplineDistanceAlpha > 1.0)
			SplineDistanceAlpha -= 1.0;

		AccLocation.AccelerateTo(TargetLocation, ActivationParams.DashDuration, DeltaTime);
		BallBoss.SetActorLocation(AccLocation.Value);
	}

	private ASkylineBallBossLocationNode SelectNextLocation() const
	{
		TListedActors<ASkylineBallBossLocationNode> Locations;
		if (Locations.Num() == 0)
			return nullptr;
		return Locations[Math::RandRange(0, Locations.Num() -1)];
	}
	
	float GetTotalDuration() const
	{
		return ActivationParams.DashDuration + ActivationParams.StayDuration;
	}

	private void Build8ShapedSpline()
	{
		const float LemniscateSize = 200.0;
		TArray<FVector> Points;
		Points.Add(FVector(0.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(0.5, 0.0, 0.5) * LemniscateSize);
		Spline.SetCustomEnterTangentPoint(Points.Last());
		Spline.SetCustomExitTangentPoint(Points.Last());
		Points.Add(FVector(1.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(0.5, 0.0, -0.5) * LemniscateSize);
		Points.Add(FVector(0.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(0.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(-0.5, 0.0, 0.5) * LemniscateSize);
		Points.Add(FVector(-1.0, 0.0, 0.0) * LemniscateSize);
		Points.Add(FVector(-0.5, 0.0, -0.5) * LemniscateSize);
		Spline.SetPoints(Points);
		Spline.SetLooping(true);
	}
}