class USanctuaryCompanionJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryCompanionJumpComponent CompanionJumpComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionJumpComp = USanctuaryCompanionJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (Player.IsAnyCapabilityActive(n"WingSuit"))
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < CompanionJumpComp.ActivateWingSuitDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.AddMovementImpulseToReachHeight(CompanionJumpComp.JumpHeight);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CompanionJumpComp.OnActivateWingSuit.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};