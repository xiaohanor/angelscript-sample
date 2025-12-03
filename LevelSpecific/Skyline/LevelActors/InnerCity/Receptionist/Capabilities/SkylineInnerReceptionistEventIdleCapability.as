class USkylineInnerReceptionistEventIdleCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	ASkylineInnerReceptionistBot Receptionist;

	float EventTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Receptionist = Cast<ASkylineInnerReceptionistBot>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Receptionist.State == ESkylineInnerReceptionistBotState::Working)
			return true;
		if (Receptionist.State == ESkylineInnerReceptionistBotState::Friendly)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Receptionist.State == ESkylineInnerReceptionistBotState::Working)
			return false;
		if (Receptionist.State == ESkylineInnerReceptionistBotState::Friendly)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		EventTimer += DeltaTime;
		if (EventTimer >= 0.5)
		{
			EventTimer = Math::Wrap(EventTimer, 0.0, 0.5);
			USkylineInnerReceptionistEventHandler::Trigger_OnIdleWorkingTicking(Receptionist);
		}
	}
};