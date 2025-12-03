class UDentistSplitToothAIRecombineStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADentistSplitToothAI SplitToothAI;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplitToothAI.State == EDentistSplitToothAIState::Recombining)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplitToothAI.State = EDentistSplitToothAIState::Recombining;
		SplitToothAI.AddActorCollisionBlock(this);

		UDentistSplitToothAIEventHandler::Trigger_OnRecombineStart(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplitToothAI.RemoveActorCollisionBlock(this);

		UDentistSplitToothAIEventHandler::Trigger_OnRecombineStop(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};