class UIslandOverseerDeployEyeManagerComponent : UActorComponent
{
	TArray<AAIIslandOverseerEye> Eyes;
	TArray<UObject> Claimants;
	TArray<UObject> PotentialClaimants;
	TArray<UObject> RemoveClaimants;
	UObject LastClaimant;
	float CooldownTime;
	float CooldownDuration = 2;

	int PhaseIndex;
	TArray<EIslandOverseerAttachedEyePhase> Phases;
	EIslandOverseerAttachedEyePhase CurrentPhase;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Phases.Add(EIslandOverseerAttachedEyePhase::FlyBy);
		Phases.Add(EIslandOverseerAttachedEyePhase::FlyBy);
		Phases.Add(EIslandOverseerAttachedEyePhase::ComboFlyBy);
		Phases.Add(EIslandOverseerAttachedEyePhase::Charge);
		Phases.Add(EIslandOverseerAttachedEyePhase::Charge);
		Phases.Add(EIslandOverseerAttachedEyePhase::ComboCharge);
		SetPhase();
	}

	private void SetPhase()
	{
		CurrentPhase = Phases[PhaseIndex];
		PhaseIndex++;
		if(PhaseIndex >= Phases.Num())
			PhaseIndex = 0;
	}

	void AddEye(AAIIslandOverseerEye Eye)
	{
		Eyes.Add(Eye);
		Eye.OnActivated.AddUFunction(this, n"OnActivated");
		Eye.OnDied.AddUFunction(this, n"OnDied");
	}

	UFUNCTION()
	private void OnDied(AAIIslandOverseerEye Eye)
	{
		PotentialClaimants.Remove(Eye);
	}

	UFUNCTION()
	private void OnActivated(AAIIslandOverseerEye Eye)
	{
		PotentialClaimants.Add(Eye);
	}

	void ClaimAttack(UObject Claimant)
	{
		Claimants.Add(Claimant);
		RemoveClaimants.Add(Claimant);
		LastClaimant = Claimant;
	}

	void ReleaseAttack(UObject Claimant)
	{
		if(RemoveClaimants.Contains(Claimant))
			RemoveClaimants.Remove(Claimant);

		if(RemoveClaimants.Num() == 0)
		{
			Claimants.Empty();
			CooldownTime = Time::GameTimeSeconds;
			SetPhase();
		}
	}

	bool CanAttack(UObject Claimant, EIslandOverseerEyeAttack Attack)
	{
		if(Time::GetGameTimeSince(CooldownTime) < CooldownDuration)
			return false;
		if(BlockFlyBy(Attack))
			return false;
		if(BlockCharge(Attack))
			return false;

		if(IsCombo())
		{
			if(Claimants.Contains(Claimant))
				return false;
		}
		else
		{
			if(Claimants.Num() > 0)
				return false;
			if(PotentialClaimants.Num() > 1 && LastClaimant == Claimant)
				return false;
		}

		return true;
	}

	bool BlockFlyBy(EIslandOverseerEyeAttack Attack)
	{
		if(Attack != EIslandOverseerEyeAttack::FlyBy)
			return false;
		 if(CurrentPhase == EIslandOverseerAttachedEyePhase::FlyBy)
		 	return false;
		 if(CurrentPhase == EIslandOverseerAttachedEyePhase::ComboFlyBy)
		 	return false;
		return true;
	}

	bool BlockCharge(EIslandOverseerEyeAttack Attack)
	{
		if(Attack != EIslandOverseerEyeAttack::Charge)
			return false;
		 if(CurrentPhase == EIslandOverseerAttachedEyePhase::Charge)
		 	return false;
		 if(CurrentPhase == EIslandOverseerAttachedEyePhase::ComboCharge)
		 	return false;
		return true;
	}

	bool IsCombo()
	{
		 if(CurrentPhase == EIslandOverseerAttachedEyePhase::ComboFlyBy)
		 	return true;
		if(CurrentPhase == EIslandOverseerAttachedEyePhase::ComboCharge)
		 	return true;
		return false;
	}
}