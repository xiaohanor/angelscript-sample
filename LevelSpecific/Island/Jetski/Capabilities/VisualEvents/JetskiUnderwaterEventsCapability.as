class UJetskiUnderwaterEventsCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AJetski Jetski;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
		MoveComp = Jetski.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Jetski.IsUnderwater())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Jetski.IsUnderwater())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UJetskiEventHandler::Trigger_OnStartUnderwaterVisual(Jetski);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UJetskiEventHandler::Trigger_OnStopUnderwaterVisual(Jetski);
	}
};