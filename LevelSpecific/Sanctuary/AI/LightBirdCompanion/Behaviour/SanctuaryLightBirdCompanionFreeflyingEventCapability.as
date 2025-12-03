class USanctuaryLightBirdCompanionFreeflyingEventCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBirdRecall);
	default CapabilityTags.Add(n"FreeFlyingEvent");
	
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::BeforeMovement;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	bool bHasReturned;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CompanionComp.IsFreeFlying())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CompanionComp.IsFreeFlying())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasReturned = false;
		ULightBirdEventHandler::Trigger_RecallStarted(Owner);
		ULightBirdEventHandler::Trigger_RecallStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ULightBirdEventHandler::Trigger_RecallStopped(Owner);
		ULightBirdEventHandler::Trigger_RecallStopped(CompanionComp.Player);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((!bHasReturned &&
			(ActiveDuration > 0.5) &&
			(CompanionComp.Player.FocusLocation.IsWithinDist(Owner.ActorLocation, 150))) || (ActiveDuration > 10))
			
		{
			bHasReturned = true;
			ULightBirdEventHandler::Trigger_RecallReturned(Owner);
		}
	}
};