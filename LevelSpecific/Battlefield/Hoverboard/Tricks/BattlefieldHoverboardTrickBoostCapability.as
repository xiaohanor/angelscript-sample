class UBattlefieldHoverboardTrickBoostCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTrickBoost);
	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardTrickComponent TrickComp;
	UPlayerMovementComponent MoveComp;

	UBattlefieldHoverboardTrickSettings TrickSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);

		TrickSettings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TrickComp.bHasPerformedTrickSinceLanding)
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > TrickSettings.TrickLandingBoostDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TrickComp.bHasPerformedTrickSinceLanding = false;

		UBattlefieldHoverboardEffectHandler::Trigger_OnTrickBoostStarted(HoverboardComp.Hoverboard);
		Player.ApplyCameraSettings(TrickSettings.TrickLandingCameraSettings, 1.0, this);
		Player.ApplyCameraImpulse(TrickSettings.TrickLandingCameraImpulse, this);
		Player.PlayCameraShake(TrickSettings.TrickLandingCameraShake, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UBattlefieldHoverboardEffectHandler::Trigger_OnTrickBoostEnded(HoverboardComp.Hoverboard);

		Player.ClearCameraSettingsByInstigator(this);
		Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / TrickSettings.TrickLandingBoostDuration;
		float CurveAlpha = TrickSettings.TrickLandingBoostCurve.GetFloatValue(Alpha);
		float Speed = TrickSettings.TrickLandingBoostMaxSpeed * CurveAlpha;

		HoverboardComp.TrickBoostSpeed = Speed;

		TEMPORAL_LOG(Player, "Hoverboard Trick")
			.Value("Trick Boost Speed", Speed)
		;
	}
};