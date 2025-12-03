class UDentistSplitToothAISplittingStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	ADentistSplitToothAI SplitToothAI;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);

		MoveComp = UHazeMovementComponent::Get(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplitToothAI.State == EDentistSplitToothAIState::Splitting)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SplitToothAI.State != EDentistSplitToothAIState::Splitting)
			return true;
		
		if(ActiveDuration < 0.5)
			return false;

		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplitToothAI.State = EDentistSplitToothAIState::Splitting;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplitToothAI.State = EDentistSplitToothAIState::Idle;
	}
};