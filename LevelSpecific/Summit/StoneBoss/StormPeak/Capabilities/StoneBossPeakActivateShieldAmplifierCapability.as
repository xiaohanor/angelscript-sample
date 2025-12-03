class UStoneBossPeakActivateShieldAmplifierCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStoneBossPeak StoneBoss;
	TArray<AStoneBossPeakShieldAmplifier> CurrentShields;
	AStoneBossPeakShieldAmplifier SelectedAmplifier;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBoss = Cast<AStoneBossPeak>(Owner);
	}

	//Network data so that it passes through activation via parameters
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!StoneBoss.ShieldAmplifierData.bShieldActive)
			return false;

		if (StoneBoss.State == EStoneBossPeakPhase::Vulnerable)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!StoneBoss.ShieldAmplifierData.bShieldActive)
			return true;

		if (StoneBoss.State == EStoneBossPeakPhase::Vulnerable)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (HasControl())
		{
			CurrentShields.Empty();

			for (int i = 0; i < StoneBoss.ShieldAmplifierData.ShieldCount - 1; i++)
			{
				StoneBoss.ShieldAmplifierProtectors[i].CrumbActivateShieldAmplifier();
				CurrentShields.AddUnique(StoneBoss.ShieldAmplifierProtectors[i]);
				StoneBoss.ShieldAmplifierProtectors[i].OnShieldAmplifierDestroyed.AddUFunction(this, n"OnShieldAmplifierDestroyed");
			}

			SelectedAmplifier = CurrentShields[0];
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//SelectedAmplifier Moves to a target location and starts shooting at the players.
	}

	UFUNCTION()
	private void OnShieldAmplifierDestroyed(AStoneBossPeakShieldAmplifier Amplifier)
	{
		CurrentShields.Remove(Amplifier);

		if (CurrentShields.Num() > 0)
		{
			SelectedAmplifier = CurrentShields[0];
		}
		else
		{

		}
	}
};