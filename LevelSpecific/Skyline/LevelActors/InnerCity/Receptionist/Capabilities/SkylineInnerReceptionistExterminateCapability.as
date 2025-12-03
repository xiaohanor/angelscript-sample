class USkylineInnerReceptionistExterminateCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineInnerReceptionistBot Receptionist;
	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	bool bKilledPlayer = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Receptionist = Cast<ASkylineInnerReceptionistBot>(Owner);
		Mio = Game::Mio;
		Zoe = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 3.0)
			return false;
		if (Receptionist.State == ESkylineInnerReceptionistBotState::ExterminateMode)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bKilledPlayer)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bKilledPlayer = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Receptionist.SetState(ESkylineInnerReceptionistBotState::Smug);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > 1.0)
		{
			bKilledPlayer = true;
			if (Receptionist.KillElectricVFX != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(Receptionist.KillElectricVFX, Mio.ActorCenterLocation);
			Mio.KillPlayer(FPlayerDeathDamageParams(), Receptionist.DeathEffect);

			Online::UnlockAchievement(n"KilledByReceptionist");
		}
	}
};