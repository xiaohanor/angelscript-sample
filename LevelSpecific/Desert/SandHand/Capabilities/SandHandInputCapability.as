struct FSandHandInputDeactivateParams
{
	bool bHoldWasStopped;
}

class USandHandInputCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(SandHand::Tags::SandHand);
	default CapabilityTags.Add(SandHand::Tags::SandHandInputCapability);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 90;

	USandHandPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USandHandPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsActioning(ActionNames::WeaponFire))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSandHandInputDeactivateParams& Params) const
	{
		if(IsActioning(ActionNames::WeaponFire))
			return false;

		// If we stopped holding after a short duration, count this as a hold
		if(ActiveDuration > SandHand::ShootDelay)
			Params.bHoldWasStopped = true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.bSandHandQueued = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSandHandInputDeactivateParams Params)
	{
		// After we stop holding, stop queueing
		// Taps should always queue and not reset after stopping a tap
		if(Params.bHoldWasStopped)
			PlayerComp.bSandHandQueued = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > SandHand::ShootDelay)
			PlayerComp.bSandHandQueued = true;
	}
}