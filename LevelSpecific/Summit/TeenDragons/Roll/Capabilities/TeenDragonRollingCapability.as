class UTeenDragonRollingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UHazeMovementComponent MoveComp;

	UTeenDragonRollSettings RollSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!RollComp.IsRolling())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!RollComp.IsRolling())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UTeenDragonRollEventHandler::Trigger_RollMovementStarted(Player);

		if (!DragonComp.bTopDownMode) 
		{
			if (!SceneView::IsFullScreen())	
				Player.ApplyCameraSettings(DragonComp.RollCameraSettings, 1, this, SubPriority = 60);
		}

		Player.ApplySettings(TeenDragonRollSteppingSettings, this, EHazeSettingsPriority::Override);
		Player.ApplySettings(TeenDragonRollStandardMovementSettings, this);

		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonDash, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeFall, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeDown, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeGrab, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonFireBreath, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonRoll, this);

		UMovementSteppingSettings::SetBottomOfCapsuleMode(Player, ESteppingMovementBottomOfCapsuleMode::Flat, this, EHazeSettingsPriority::Gameplay);

		Player.PlayForceFeedback(RollComp.RollStartRumble, false, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);

		UTeenDragonRollEventHandler::Trigger_RollEnded(Player);
		UTeenDragonRollVFX::Trigger_OnRollEnded(Player);

		Player.ClearCameraSettingsByInstigator(this);
		Player.StopCameraShakeByInstigator(this);

		Player.ClearSettingsByInstigator(this);	

		RollComp.bRollIsStarted = false;
		DragonComp.bWillHitObjectWhileRollJumping = false;

		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonDash, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeFall, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeDown, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeGrab, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonFireBreath, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonRoll, this);
	
		UMovementSteppingSettings::ClearBottomOfCapsuleMode(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!DragonComp.bTopDownMode
		&& MoveComp.IsOnAnyGround())
		{
			float SpeedAlpha = Player.ActorVelocity.Size() / RollSettings.MaximumRollSpeed;
			Player.PlayCameraShake(DragonComp.RollContinuousCameraShake, this, SpeedAlpha);
		}
		else
		{
			Player.StopCameraShakeByInstigator(this);
		}

		if (!SceneView::IsFullScreen())	
			Player.ClearCameraSettingsByInstigator(this);
	}
};