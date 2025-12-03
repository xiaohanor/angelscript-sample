class USanctuaryLightBirdShieldDarknessSlowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SanctuaryDarknessSlow");
	default CapabilityTags.Add(n"LightBirdShield");

	default TickGroup = EHazeTickGroup::BeforeMovement;

	USanctuaryLightBirdShieldUserComponent UserComp;

	float PlayerMaximumSpeed = 80.0;
	float PlayerMinimumSpeed = 40.0;

	float PlayerMaximumJumpImpulse = 0.0;
	float PlayerMinimumJumpImpulse = SMALL_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USanctuaryLightBirdShieldUserComponent::Get(Owner);
		PlayerMaximumSpeed = Player.GetSettings(UPlayerFloorMotionSettings).MaximumSpeed;
		PlayerMaximumJumpImpulse = Player.GetSettings(UPlayerJumpSettings).Impulse;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsActive)
			return false;

		if (UserComp.DarknessAmount < 0.0 + SMALL_NUMBER)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bIsActive)
			return true;

		if (UserComp.DarknessAmount < 0.0 + SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Settings : UserComp.Settings.DarknessSettings)
			Player.ApplySettings(Settings, this);

		for (auto Tag : UserComp.Settings.BlockTagsInDarkness)
			Player.BlockCapabilities(Tag, this);

		Player.PlayForceFeedback(UserComp.Settings.DarknessForceFeedbackEffect, true, true, this);

//		Player.PlaySlotAnimation(Animation = UserComp.Settings.DarknessDownAnim, bLoop = true, BlendTime = 0.5);

		UPlayerFloorMotionSettings::SetFacingDirectionInterpSpeed(Player, 6.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
		
		for (auto Tag : UserComp.Settings.BlockTagsInDarkness)
			Player.UnblockCapabilities(Tag, this);

		Player.StopForceFeedback(this);

//		Player.StopSlotAnimationByAsset(UserComp.Settings.DarknessDownAnim);
		UPlayerFloorMotionSettings::ClearFacingDirectionInterpSpeed(Player, this);
		UPlayerFloorMotionSettings::ClearMaximumSpeed(Player, this);
		UPlayerJumpSettings::ClearImpulse(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < 0.5)
			return;
		
		if (Player.IsOnWalkableGround())
			Player.RequestLocomotion(n"DarknessCrawl", this);

		UPlayerFloorMotionSettings::SetMaximumSpeed(Player, Math::Max((1.0 - UserComp.DarknessAmount * 12.0) * PlayerMaximumSpeed, PlayerMinimumSpeed), this);
		UPlayerJumpSettings::SetImpulse(Player, Math::Max((1.0 - UserComp.DarknessAmount) * PlayerMaximumSpeed, PlayerMinimumSpeed), this);
	}
};