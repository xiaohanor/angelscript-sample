class UPlayerSwimmingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swimming);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerSwimmingComponent SwimmingComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	bool bHasBlockedDash = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (SwimmingComp.InstigatedSwimmingState.Get() != EPlayerSwimmingActiveState::Active)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (SwimmingComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Swimming, this);
		Player.BlockCapabilities(PlayerSwimmingTags::SwimmingDash, this);
		bHasBlockedDash = true;

		MoveComp.ApplyCustomMovementStatus(PlayerMovementTags::Swimming, this);

		// Don't follow any moving ground or inherit movement zones while swimming unless specified in settings
		if(!SwimmingComp.Settings.bAllowFollowMovement)
			MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowDisabled, EInstigatePriority::High);

		Player.CapsuleComponent.OverrideCapsuleRadius(SwimmingComp.Settings.SwimmingCapsuleRadius, this);

		// Reset eventual movement options
		Player.ResetWallScrambleUsage();
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Swimming, this);

		if(bHasBlockedDash)
		{
			Player.UnblockCapabilities(PlayerSwimmingTags::SwimmingDash, this);
			bHasBlockedDash = false;
		}

		Player.ClearMovementInput(this);
		MoveComp.ClearCustomMovementStatus(this);

		MoveComp.ClearFollowEnabledOverride(this);

		if(SwimmingComp.GetState() == EPlayerSwimmingState::Underwater && !Player.IsPlayerDead())
			UPlayerSwimmingEffectHandler::Trigger_Underwater_ExitBypassedSurface(Player, FSwimmingEffectEventData());
		
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);
		Player.ClearCameraSettingsByInstigator(SwimmingComp, 2);
		
		SwimmingComp.SetState(EPlayerSwimmingState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(bHasBlockedDash && ActiveDuration >= 0.3)
		{
			Player.UnblockCapabilities(PlayerSwimmingTags::SwimmingDash, this);
			bHasBlockedDash = false;
		}
	}
}