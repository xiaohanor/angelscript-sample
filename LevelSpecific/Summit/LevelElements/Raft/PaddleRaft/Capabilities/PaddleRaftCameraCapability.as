class UPaddleRaftCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);

	default DebugCategory = SummitRaftDebug::SummitRaft;

	default TickGroup = EHazeTickGroup::AfterGameplay;

	APaddleRaft Raft;
	UCameraUserComponent CameraUserComp;
	FHazeAcceleratedRotator AccCameraRotation;

	const float CameraAccelerationDuration = 1.5;

	TPerPlayer<bool> BlockedCameraPlayers;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Raft = Cast<APaddleRaft>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Raft.bHasStarted)
			return false;

		if (Raft.IsActorDisabled())
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
		if (!Raft.bHasStarted)
			return true;

		if (Raft.IsActorDisabled())
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
		AccCameraRotation.SnapTo(CameraUserComp.ControlRotation, CameraUserComp.ViewAngularVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Player : Game::Players)
		{
			if (BlockedCameraPlayers[Player])
				Player.UnblockCapabilities(CameraTags::CameraControl, this);

			BlockedCameraPlayers[Player] = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!CameraUserComp.CanControlCamera())
			return;

		FRotator TargetCameraRotation = CameraUserComp.ControlRotation;
		FRotator TargetYawRotation = FRotator::MakeFromX(Raft.ActorForwardVector);
		TargetCameraRotation.Yaw = TargetYawRotation.Yaw;
		AccCameraRotation.AccelerateTo(TargetCameraRotation, CameraAccelerationDuration, DeltaTime);
		CameraUserComp.SetDesiredRotation(AccCameraRotation.Value, this);
	}
};