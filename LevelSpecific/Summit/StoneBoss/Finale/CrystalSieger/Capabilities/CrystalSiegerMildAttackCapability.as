class UCrystalSiegerMildAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ACrystalSieger CrystalSieger;

	float AttackRate = 3.0;
	float AttackTime;

	int LastLine;

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

		if (!CrystalSieger.bMildAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CrystalSieger.bSiegerEnabled)
			return true;

		if (!CrystalSieger.bMildAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttackTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		while (Time::GameTimeSeconds > AttackTime)
		{
			//Ignore first and last lines
			int RLine = Math::RandRange(1, CrystalSieger.LineAttackActors.Num() - 2);
			
			if (CrystalSieger.LineAttackActors.Num() > 1)
			{
				while (RLine == LastLine)
					RLine = Math::RandRange(1, CrystalSieger.LineAttackActors.Num() - 2);
			}

			LastLine = RLine;
			
			AttackTime += AttackRate;
			CrystalSieger.LineAttackActors[RLine].FireAttack();
		}
	}
};