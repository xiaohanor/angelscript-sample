class UDentistSplitToothAIIdleStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	ADentistSplitToothAI SplitToothAI;
	UHazeMovementComponent MoveComp;

	FVector CurrentInput;
	float LastUpdateInputTime = 0;
	float InputDuration = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);
		InputDuration = 1;

		MoveComp = SplitToothAI.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplitToothAI.State == EDentistSplitToothAIState::Idle)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SplitToothAI.State != EDentistSplitToothAIState::Idle)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplitToothAI.State = EDentistSplitToothAIState::Idle;
		GenerateNewRightInput();

		UDentistSplitToothAIEventHandler::Trigger_OnIdleStart(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearMovementInput(this);

		UDentistSplitToothAIEventHandler::Trigger_OnIdleStop(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ShouldGenerateNewRightInput())
			GenerateNewRightInput();
		
		MoveComp.ApplyMovementInput(CurrentInput, this);
	}

	bool ShouldGenerateNewRightInput() const
	{
		if(Time::GetGameTimeSince(LastUpdateInputTime) < InputDuration)
			return false;

		return true;
	}

	void GenerateNewRightInput()
	{
		CurrentInput = Math::GetRandomPointInCircle_XY();
		LastUpdateInputTime = Time::GameTimeSeconds;
		InputDuration = SplitToothAI.Settings.InputDuration.Rand();
	}
};