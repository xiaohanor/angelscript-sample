class UWaveRaftRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default TickGroup = EHazeTickGroup::Input;
	default DebugCategory = SummitRaftDebug::SummitRaft;

	AWaveRaft WaveRaft;

	UWaveRaftSettings RaftSettings;

	TPerPlayer<UWaveRaftPlayerComponent> RaftComps;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaveRaft = Cast<AWaveRaft>(Owner);
		MoveComp = UHazeMovementComponent::Get(WaveRaft);

		RaftSettings = UWaveRaftSettings::GetSettings(WaveRaft);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WaveRaft.SplinePos.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Player : Game::Players)
			RaftComps[Player] = UWaveRaftPlayerComponent::Get(Player);

		WaveRaft.AccWaveRaftRotation.SnapTo(WaveRaft.ActorRotation);
		WaveRaft.TargetYawOffsetFromSpline = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(HasControl())
		// {
		// 	FRotator TargetRotation = WaveRaft.SplinePos.WorldRotation.Rotator();

		// 	bool bIsPaddleBreaking = false;
		// 	for(auto Player : Game::Players)
		// 	{
		// 		auto BreakState = RaftComps[Player].BreakState;
		// 		auto OtherPlayerBreakState = RaftComps[Player.OtherPlayer].BreakState;
		// 		if(BreakState == EWaveRaftPaddleBreakDirection::LeftIdle
		// 		|| BreakState == EWaveRaftPaddleBreakDirection::RightIdle)
		// 			continue;

		// 		// float AdditionalYaw = RaftSettings.PaddleBreakSpeed * DeltaTime;

		// 		// if(BreakState != OtherPlayerBreakState)
		// 		// 	AdditionalYaw *= RaftSettings.PaddleBreakSoloRotationFraction;

		// 		// if(BreakState == EWaveRaftPaddleBreakDirection::Left)
		// 		// 	WaveRaft.TargetYawOffsetFromSpline -= AdditionalYaw;
		// 		// else if(BreakState == EWaveRaftPaddleBreakDirection::Right)
		// 		// 	WaveRaft.TargetYawOffsetFromSpline += AdditionalYaw;

		// 		bIsPaddleBreaking = true;
		// 	}

		// 	WaveRaft.TargetYawOffsetFromSpline = Math::Clamp(WaveRaft.TargetYawOffsetFromSpline, -RaftSettings.MaxYawFromSpline, RaftSettings.MaxYawFromSpline);

		// 	TargetRotation += FRotator(0, WaveRaft.TargetYawOffsetFromSpline, 0);
		// 	TargetRotation.Pitch = 0.0;
		// 	TargetRotation.Roll = 0.0;

		// 	if(MoveComp.IsOnAnyGround())
		// 		WaveRaft.AccWaveRaftRotation.AccelerateTo(TargetRotation, RaftSettings.OnGroundPaddleBreakingRotationDuration, DeltaTime);
		// 	else
		// 		WaveRaft.AccWaveRaftRotation.SpringTo(TargetRotation, RaftSettings.InWaterPaddleBreakingRotationSpeed, 0.2, DeltaTime);
		// }
	}
};