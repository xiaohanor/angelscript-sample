class UCrystalSiegerCircleAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ACrystalSieger CrystalSieger;

	float WaitTime = 2.0;
	float AttackTime;

	TPerPlayer<FVector> LastGroundImpact;

	bool bDeactivate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CrystalSieger = Cast<ACrystalSieger>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CrystalSieger.bSiegerEnabled)
			return false;

		if (!CrystalSieger.bCircleAttacks)
			return false;

		if (!CrystalSieger.ConsumeHit())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CrystalSieger.bSiegerEnabled)
			return true;
		
		if (bDeactivate)
			return true;

		if (!CrystalSieger.bCircleAttacks)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bDeactivate = false;
		AttackTime = Time::GameTimeSeconds + WaitTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CrystalSieger.ResetHit();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > AttackTime && !bDeactivate)
		{
			bDeactivate = true;
			CrystalSieger.CircleAttack.FireAttack();
		}
	}
};