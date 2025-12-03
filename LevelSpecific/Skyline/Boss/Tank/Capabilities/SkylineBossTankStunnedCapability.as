class USkylineBossTankStunnedCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankMovement);

	FHazeAcceleratedFloat Speed;

	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BossTank.State.Get() != ESkylineBossTankState::Stunned)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > BossTank.StunDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BossTank.OnStun.Broadcast();

		Velocity = BossTank.Velocity;
		float InitialSpeed = Velocity.Size();
		Speed.SnapTo(InitialSpeed, InitialSpeed);

		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankWeakPoint, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);

		USkylineBossTankEventHandler::Trigger_OnStunnedStart(BossTank);

		FSkylineBossTankLight LightSettings;
		LightSettings.Color = FLinearColor::Black;
		LightSettings.BlendTime = 1.0;
		LightSettings.Freq = 10.0;
		LightSettings.FreqAlpha = 0.5;
		BossTank.LightComp.ApplyLightSettings(LightSettings, this);

		FCenterViewForcedTarget CenterViewForcedTarget;
		CenterViewForcedTarget.Instigator = BossTank;
		CenterViewForcedTarget.Priority = EInstigatePriority::Normal;
		CenterViewForcedTarget.Target = BossTank.CenterViewTargetComp;
		CenterViewForcedTarget.Params.bRequireInputToActivate = false;
		CenterViewForcedTarget.Params.bShowTutorial = false;
		CenterViewForcedTarget.Params.bAllowCameraInputToDeactivate = false;
		CenterViewForcedTarget.Params.bAllowCenterViewInputToDeactivate = false;
		CenterViewForcedTarget.Params.bClearOnDeactivate = true;

		// No locked camera
/*
		for (auto Player : Game::Players)
		{
			Player.ApplyForcedCenterViewTarget(CenterViewForcedTarget);
		}
*/
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankWeakPoint, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);

		USkylineBossTankEventHandler::Trigger_OnStunnedEnd(BossTank);

		BossTank.LightComp.ClearLightSettings(this);

		for (auto Player : Game::Players)
			BossTank.GetBikeFromTarget(Player).ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		Speed.AccelerateTo(0.0, 2.0, DeltaTime);
		BossTank.Velocity = Velocity.SafeNormal * Speed.Value;
	}

	void TickRemote(float DeltaTime)
	{
		const FHazeSyncedActorPosition& Position = BossTank.SyncedActorPositionComp.GetPosition();	
		BossTank.SetActorVelocity(Position.WorldVelocity);
	}
}