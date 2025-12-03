class UPlayerSwingRopeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);

	default TickGroup = EHazeTickGroup::PostWork;

	UPlayerSwingComponent SwingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingComp = UPlayerSwingComponent::Get(Player);
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
		SwingComp.DecativateRopeVisuals();
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
				
				if(SwingComp.FF_Rope_Connect != nullptr)
					Player.PlayForceFeedback(SwingComp.FF_Rope_Connect, this);
			}
		}
	}

	void TargetReached()
	{
		// rope has reached target
		SwingComp.VisualRopeFullyExtended();
	}
}