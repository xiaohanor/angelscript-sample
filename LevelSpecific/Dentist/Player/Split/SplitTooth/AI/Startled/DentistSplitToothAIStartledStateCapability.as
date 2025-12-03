class UDentistSplitToothAIStartledStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADentistSplitToothAI SplitToothAI;
	FHazeActionQueue ActionQueue;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);
		ActionQueue.Initialize(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Can only get startled if idling around
		if(SplitToothAI.State != EDentistSplitToothAIState::Idle)
			return false;

		const bool bIsClose = SplitToothAI.ActorLocation.Distance(SplitToothAI.OwningPlayer.ActorLocation) < SplitToothAI.Settings.StartleDistance;

		if(!bIsClose)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActionQueue.IsEmpty())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplitToothAI.State = EDentistSplitToothAIState::Startled;

		ActionQueue.Capability(UDentistSplitToothAIStartledTurnAroundCapability);
		ActionQueue.Capability(UDentistSplitToothAIStartledJumpCapability);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplitToothAI.State = EDentistSplitToothAIState::Scared;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ActionQueue.Update(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("ActionQueue", ActionQueue);
	}
};