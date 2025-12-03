class UTundraPlayerOtterSwimmingCapability : UHazePlayerCapability
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

	UTundraPlayerOtterComponent OtterComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerOtterSwimmingComponent SwimmingComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	FHazeAcceleratedFloat AcceleratedEmissiveStrength;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OtterComp = UTundraPlayerOtterComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SwimmingComp = UTundraPlayerOtterSwimmingComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		AcceleratedEmissiveStrength.AccelerateTo(IsActive() ? 5.0 : 0.0, 1.0, DeltaTime);
		float Val = AcceleratedEmissiveStrength.Value;
		FLinearColor Color = FLinearColor(Val, Val, Val, 1.0);
		OtterComp.GetShapeMesh().SetColorParameterValueOnMaterials(n"EmissiveTint", Color);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (SwimmingComp.InstigatedSwimmingActiveState.Get() != ETundraPlayerOtterSwimmingActiveState::Active)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (SwimmingComp.InstigatedSwimmingActiveState.Get() == ETundraPlayerOtterSwimmingActiveState::Inactive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Swimming, this);
		Player.BlockCapabilities(PlayerMovementTags::PoleClimb, this);
		MoveComp.ApplyCustomMovementStatus(PlayerMovementTags::Swimming, this);

		// Don't follow any moving ground or inherit movement zones while swimming
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowDisabled, EInstigatePriority::High);

		// Reset eventual movement options
		Player.ResetWallScrambleUsage();
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Swimming, this);
		Player.UnblockCapabilities(PlayerMovementTags::PoleClimb, this);
		Player.ClearMovementInput(this);
		MoveComp.ClearCustomMovementStatus(this);

		MoveComp.ClearFollowEnabledOverride(this);

		Player.ClearCameraSettingsByInstigator(SwimmingComp, 2);

		SwimmingComp.SetCurrentState(ETundraPlayerOtterSwimmingState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
	}
}