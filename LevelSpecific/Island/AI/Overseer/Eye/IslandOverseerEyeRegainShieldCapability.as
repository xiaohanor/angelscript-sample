class UIslandOverseerEyeRegainShieldCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AAIIslandOverseerEye Eye;
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;
	bool bRegenerated;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Eye = Cast<AAIIslandOverseerEye>(Owner);
		ForceFieldBubbleComp = UIslandForceFieldBubbleComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Eye.Active)
			return false;
		if(Eye.HealthComp.IsDead())
			return false;
		if(!ForceFieldBubbleComp.IsDepleted())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bRegenerated)
			return true;
		if(!Eye.Active)
			return true;
		if(Eye.HealthComp.IsDead())
			return true;
		if(!ForceFieldBubbleComp.IsDepleted())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bRegenerated = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < 5)
			return;

		if(HasControl())
			ForceFieldBubbleComp.CrumbReset();
		bRegenerated = true;
	}
}