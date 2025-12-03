class UWaveRaftStaggerRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	AWaveRaft WaveRaft;
	UWaveRaftSettings RaftSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaveRaft = Cast<AWaveRaft>(Owner);
		RaftSettings = UWaveRaftSettings::GetSettings(WaveRaft);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WaveRaft.StaggerData.IsSet())
			return false;

		if (WaveRaft.StaggerData.Value.bSmallHit)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > RaftSettings.StaggerMinDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WaveRaft.BlockCapabilities(SummitRaftTags::BlockedWhileInHitStagger, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WaveRaft.UnblockCapabilities(SummitRaftTags::BlockedWhileInHitStagger, this);
		WaveRaft.StaggerData.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator NewRotation = FRotator::MakeFromXZ((WaveRaft.StaggerData.Value.ReflectedVelocity.GetSafeNormal() + WaveRaft.SplinePos.WorldForwardVector) * 0.5, WaveRaft.ActorUpVector);

		// Debug::DrawDebugDirectionArrow(WaveRaft.ActorLocation + FVector::UpVector * 200, NewRotation.ForwardVector, 1000, 20, FLinearColor::Red);
		WaveRaft.AccWaveRaftRotation.AccelerateTo(NewRotation, 0.75, DeltaTime);
		float YawDelta = WaveRaft.AccWaveRaftRotation.Value.Yaw - WaveRaft.ActorRotation.Yaw;
		WaveRaft.AccYawSpeed.SnapTo(YawDelta);
	}
};