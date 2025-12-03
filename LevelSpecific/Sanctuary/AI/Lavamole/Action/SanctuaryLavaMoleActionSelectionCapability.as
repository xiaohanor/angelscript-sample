class USanctuaryLavaMoleActionSelectionCapability : UHazeCapability
{
	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);
	UHazeActionQueueComponent ActionComp;
	AAISanctuaryLavamole Mole;
	USanctuaryLavamoleSettings Settings;

	ESanctuaryLavamoleMortarTargetingStrategy LastAggressiveStrategy;

	int PredictedShots = 0;
	int ChaseShots = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActionComp = UHazeActionQueueComponent::GetOrCreate(Owner);
		Mole = Cast<AAISanctuaryLavamole>(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (Mole.Bite1Comp.IsBitten())
			return false;
		if (Mole.Bite2Comp.IsBitten())
			return false;
		if (Mole.HealthComp.CurrentHealth < 0.1)
			return false;
		if (ActionComp.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ActionComp.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Mole.bIsAggressive)
		{
			// PrintToScreen("AGGRESS", 5.0);
			AggressiveMoleBehavior();
		}
		else
		{
			// PrintToScreen("NORMIE", 5.0);
			NormalMoleBehavior();
		}
	}

	private void AggressiveMoleBehavior()
	{
		bool bInSafeHole = Mole.IsInSafeHole();
		if (!bInSafeHole)
			ActionComp.Event(Mole, n"SwitchHole");

		ActionComp.Event(this, n"TryToBeAggressive");
	}

	UFUNCTION()
	private void TryToBeAggressive()
	{
		bool bInSafeHole = Mole.IsInSafeHole();
		if (!bInSafeHole)
		{
			NormalMoleBehavior();
			return;
		}
		if (Mole.bIsUnderground)
		{
			DigUpAnticipate();
			DigUp();
		}
		// for (int i = 0; i < Settings.NumSpamMortarProjectiles; ++i)
		{
			MortarAnticipateProjectile(0.1); 
			MortarAggressiveProjectile();
		}
		// ActionComp.ActionQueue.Idle(1.0);
	}

	private void NormalMoleBehavior()
	{
		if (!Mole.bIsUnderground)
			DigDown();
		// SwitchHole();
		ActionComp.Event(Mole, n"SwitchHole");
		DigUpAnticipate();
		DigUp();
		if (SanctuaryCentipedeDevToggles::Mole::MoleChilling.IsEnabled())
			ActionComp.Idle(100000);
		
		for (int i = 0; i < Mole.NumMortarsToShoot; ++i)
		{
			// full anticipation or just cooldown!
			float AnticipationDuration = i == 0 ? Math::RandRange(Settings.MinProjectileAnticipationDuration, Settings.MaxProjectileAnticipationDuration) : Settings.MortarCooldown;
			MortarAnticipateProjectile(AnticipationDuration); 
			MortarProjectile();
		}
		ActionComp.Idle(Math::RandRange(Settings.MinProjectileRecoveryDuration, Settings.MaxProjectileRecoveryDuration));
		DigDown();
	}

	private void DigUpAnticipate()
	{
		ActionComp.Capability(USanctuaryLavamoleActionDigUpAnticipationCapability, FSanctuaryLavamoleActionDigUpAnticipationData());
	}

	private void DigUp()
	{
		ActionComp.Capability(USanctuaryLavamoleActionDigUpCapability, FSanctuaryLavamoleActionDigUpData());
	}

	private void MortarAnticipateProjectile(float AnticipationDuration)
	{
		FSanctuaryLavamoleActionMortarAnticipationData Data;
		Data.Duration = AnticipationDuration;
		ActionComp.Capability(USanctuaryLavamoleActionMortarAnticipationCapability, Data);
	}

	private void MortarProjectile()
	{
		ActionComp.Capability(USanctuaryLavamoleActionMortarLaunchCapability, FSanctuaryLavamoleActionMortarQueueData());
	}

	private void MortarAggressiveProjectile()
	{
		FSanctuaryLavamoleActionMortarQueueData Data;
		Data.SpeedMultiplier = Mole.bIsAggressive ? 1.5 : 1.0 ;
		Data.TargetingStrategy = GetUpdatedStrategy();
		ActionComp.Capability(USanctuaryLavamoleActionMortarLaunchCapability, Data);
	}

	private ESanctuaryLavamoleMortarTargetingStrategy GetUpdatedStrategy()
	{
		bool bLastShotZoe = LastAggressiveStrategy == ESanctuaryLavamoleMortarTargetingStrategy::ChaseZoe || LastAggressiveStrategy == ESanctuaryLavamoleMortarTargetingStrategy::PredictZoe;
		bool bMioViable = Game::Mio.IsAnyCapabilityActive(CentipedeTags::CentipedeBite);
		bool bZoeViable = Game::Zoe.IsAnyCapabilityActive(CentipedeTags::CentipedeBite);

		bool bTargetMio = false;

		// every other player if both grabs
		if (bMioViable && bZoeViable)
		{
			if (bLastShotZoe)
				bTargetMio = true;
			else
				bTargetMio = false;
		}
		else if (bMioViable)
			bTargetMio = true;
		else
			bTargetMio = false;

		bool bUsePredicted = true;//PredictedShots < 2;
		if (bTargetMio && bUsePredicted)
			LastAggressiveStrategy = ESanctuaryLavamoleMortarTargetingStrategy::PredictMio;
		else if (!bTargetMio && bUsePredicted)
			LastAggressiveStrategy = ESanctuaryLavamoleMortarTargetingStrategy::PredictZoe;
		else if (bTargetMio && !bUsePredicted)
			LastAggressiveStrategy = ESanctuaryLavamoleMortarTargetingStrategy::ChaseMio;
		else if (!bTargetMio && !bUsePredicted)
			LastAggressiveStrategy = ESanctuaryLavamoleMortarTargetingStrategy::ChaseZoe;

		if (bUsePredicted)
		{
			PredictedShots++;
			if (PredictedShots >= 2)
				ChaseShots = 0;
		}
		else
		{
			ChaseShots++;
			if (ChaseShots >= 2)
				PredictedShots = 0;
		}

		return LastAggressiveStrategy;
	}

	private void DigDown()
	{
		ActionComp.Capability(USanctuaryLavamoleActionDigDownCapability, FSanctuaryLavamoleActionDigDownData());
	}
}
