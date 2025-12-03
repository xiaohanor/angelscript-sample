class UWaveRaftCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default CapabilityTags.Add(CameraTags::Camera);
	default DebugCategory = SummitRaftDebug::SummitRaft;
	default TickGroup = EHazeTickGroup::AfterGameplay;

	AWaveRaft WaveRaft;
	UCameraUserComponent CameraUserComp;
	UHazeMovementComponent MoveComp;
	FHazeAcceleratedRotator AccCameraRotation;

	const float CameraAccelerationDuration = 1.5;

	AHazePlayerCharacter PlayerToBlockCameraControlOn;

	TPerPlayer<bool> BlockedCameraPlayers;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaveRaft = Cast<AWaveRaft>(Owner);
		MoveComp = UHazeMovementComponent::Get(WaveRaft);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WaveRaft.bHasStarted)
			return false;

		if (WaveRaft.IsActorDisabled())
			return false;

		if (SceneView::FullScreenPlayer == nullptr)
			return false;

		if (SceneView::FullScreenPlayer.bIsParticipatingInCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!WaveRaft.bHasStarted)
			return true;

		if (WaveRaft.IsActorDisabled())
			return true;

		if (SceneView::FullScreenPlayer == nullptr)
			return true;

		if (SceneView::FullScreenPlayer.bIsParticipatingInCutscene)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Player : Game::Players)
		{
			Player.BlockCapabilities(CameraTags::CameraControl, this);
			BlockedCameraPlayers[Player] = true;
		}
		CameraUserComp = UCameraUserComponent::Get(SceneView::FullScreenPlayer);
		if (WaveRaft.bHasQueuedCameraSnap)
		{
			FRotator TargetCameraRotation = CameraUserComp.ControlRotation;
			FRotator TargetYawRotation = FRotator::MakeFromX(WaveRaft.SplinePos.WorldForwardVector);
			TargetCameraRotation.Yaw = TargetYawRotation.Yaw;
			TargetCameraRotation.Pitch = 0;
			AccCameraRotation.SnapTo(TargetCameraRotation, CameraUserComp.ViewAngularVelocity);
			WaveRaft.bHasQueuedCameraSnap = false;
		}
		else
		{
			AccCameraRotation.SnapTo(CameraUserComp.ControlRotation, CameraUserComp.ViewAngularVelocity);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Player : Game::Players)
		{
			if (BlockedCameraPlayers[Player])
				Player.UnblockCapabilities(CameraTags::CameraControl, this);

			Player.StopCameraShakeByInstigator(this);
			BlockedCameraPlayers[Player] = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!CameraUserComp.CanControlCamera())
			return;

		FRotator TargetCameraRotation = CameraUserComp.ControlRotation;
		FRotator TargetYawRotation = FRotator::MakeFromX(WaveRaft.SplinePos.WorldForwardVector);
		TargetCameraRotation.Yaw = TargetYawRotation.Yaw;
		TargetCameraRotation.Pitch = 0;
		AccCameraRotation.AccelerateTo(TargetCameraRotation, CameraAccelerationDuration, DeltaTime);
		CameraUserComp.SetDesiredRotation(AccCameraRotation.Value, this);
	}
};