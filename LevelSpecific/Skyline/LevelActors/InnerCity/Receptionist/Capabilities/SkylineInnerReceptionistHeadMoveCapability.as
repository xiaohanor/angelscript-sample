class USkylineInnerReceptionistHeadMoveCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	FHazeAcceleratedFloat AccRelativeZ;
	ASkylineInnerReceptionistBot Receptionist;

	float OGRelativeZ = 0.0;

	float PlayerZWeight = 10.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Receptionist = Cast<ASkylineInnerReceptionistBot>(Owner);
		OGRelativeZ = Receptionist.HeadMesh.RelativeLocation.Z;
		AccRelativeZ.SnapTo(OGRelativeZ);
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (IsInHandledState())
			return true;
		if (Receptionist.PlayersAreOnTop())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (IsInHandledState())
			return false;
		if (Receptionist.PlayersAreOnTop())
			return false;
		if (Math::Abs(AccRelativeZ.Velocity) > 0.1)
			return false;
		if (!Math::IsNearlyEqual(OGRelativeZ, AccRelativeZ.Value))
			return false;
		return true;
	}

	bool IsInHandledState() const
	{
		if (Receptionist.State == ESkylineInnerReceptionistBotState::Afraid)
			return true;
		if (Receptionist.State == ESkylineInnerReceptionistBotState::Bracing)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsInHandledState())
		{
			AccRelativeZ.AccelerateTo(OGRelativeZ - 25.0, 0.5, DeltaTime);
		}
		else if (Receptionist.PlayersAreOnTop())
		{
			float TargetZ = OGRelativeZ;
			if (Receptionist.PlayersOnTop[Game::Mio])
				TargetZ -= PlayerZWeight;
			if (Receptionist.PlayersOnTop[Game::Zoe])
				TargetZ -= PlayerZWeight;

			AccRelativeZ.SpringTo(TargetZ, 50.0, 0.7, DeltaTime);
		}
		else
			AccRelativeZ.AccelerateTo(OGRelativeZ, 1.0, DeltaTime);

		Receptionist.HeadMesh.SetRelativeLocation(FVector(0.0, 0.0, AccRelativeZ.Value));
	}
};