class UBattlefieldHoverboardSwingRopeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);

	default TickGroup = EHazeTickGroup::PostWork;

	UBattlefieldHoverboardSwingComponent SwingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingComp = UBattlefieldHoverboardSwingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwingComp.HasActivateSwingPoint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwingComp.HasActivateSwingPoint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bTargetReached = false;
		SwingComp.ActivateRopeVisuals();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwingComp.DeactivateRopeVisuals();
	}

	bool bTargetReached = false;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SwingComp.UpdateRopeVisuals();

		if(bTargetReached == false)
		{
			if(ActiveDuration >= SwingComp.Settings.ExtendRopeDuration)
			{
				TargetReached();
				bTargetReached = true;
			}
		}
	}

	void TargetReached()
	{
		// rope has reached target
		SwingComp.VisualRopeFullyExtended();
	}
}