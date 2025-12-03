class UMoonMarketPlayerSoulCollectCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketPlayerSoulCollectComponent UserComp;

	float AnimTime = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UMoonMarketPlayerSoulCollectComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsCollectingSoul)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > AnimTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// FHazePointOfInterestFocusTargetInfo TargetInfo;
		// TargetInfo.SetFocusToActor(UserComp.TargetCat);
		// TargetInfo.ViewOffset = FVector(0,0,200);
		// FApplyPointOfInterestSettings POISettings;
		// POISettings.Duration = AnimTime;
		// Player.ApplyPointOfInterest(this, TargetInfo, POISettings, 1.5);

		AnimTime = UserComp.TargetCat.SoulCatchTime;

		FHazeSlotAnimSettings Settings;
		Settings.BlendTime = AnimTime / 3.5;
		Settings.PlayRate = 0.75;
		Player.PlaySlotAnimation(UserComp.Animation, Settings);
		Player.ApplyCameraSettings(UserComp.PlayerCameraSettings, AnimTime, this);

		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.TargetCat.CatchCatSoul(Player);
		Player.StopAllSlotAnimations();
		Player.ClearCameraSettingsByInstigator(this);
		UserComp.bIsCollectingSoul = false;
		Player.ClearPointOfInterestByInstigator(this);

		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.SetMovementFacingDirection((UserComp.TargetCat.ActorLocation - Player.ActorLocation).Rotation());
	}
};