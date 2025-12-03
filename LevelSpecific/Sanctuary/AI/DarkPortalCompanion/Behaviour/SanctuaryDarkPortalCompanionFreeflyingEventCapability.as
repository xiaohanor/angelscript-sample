class USanctuaryDarkPortalCompanionFreeflyingEventCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalRecall);
	default CapabilityTags.Add(n"FreeFlyingEvent");
	
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::BeforeMovement;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	bool bHasReturned = false;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::Get(Owner);
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
		UDarkPortalEventHandler::Trigger_CompanionRecallStarted(Owner);
		UDarkPortalEventHandler::Trigger_CompanionRecallStarted(CompanionComp.Player);
		bHasReturned = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UDarkPortalEventHandler::Trigger_CompanionRecallStopped(Owner);
		UDarkPortalEventHandler::Trigger_CompanionRecallStopped(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((!bHasReturned &&
			(ActiveDuration > 0.5) &&
			(CompanionComp.Player.FocusLocation.IsWithinDist(Owner.ActorLocation, 100))) || (ActiveDuration > 10))
			
		{
			bHasReturned = true;
			UDarkPortalEventHandler::Trigger_CompanionRecallReturned(Owner);
		}
	}
};