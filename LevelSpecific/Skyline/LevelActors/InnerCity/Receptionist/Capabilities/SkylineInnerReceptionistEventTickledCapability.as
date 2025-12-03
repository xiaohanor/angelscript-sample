class USkylineInnerReceptionistEventTickledCapability : UHazeCapability
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
		if (Receptionist.State != ESkylineInnerReceptionistBotState::Laughing)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Receptionist.State != ESkylineInnerReceptionistBotState::Laughing)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		USkylineInnerReceptionistEventHandler::Trigger_OnReactToZoeStartTickleReceptionist(Receptionist);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		USkylineInnerReceptionistEventHandler::Trigger_OnReactToZoeStopTickleReceptionist(Receptionist);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		EventTimer += DeltaTime;
		if (EventTimer >= 0.5)
		{
			EventTimer = Math::Wrap(EventTimer, 0.0, 0.5);
			USkylineInnerReceptionistEventHandler::Trigger_OnReactToZoeTickleReceptionistTicking(Receptionist);
		}
	}
};