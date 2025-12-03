class UCrystalSiegerIntroAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ACrystalSieger CrystalSieger;

	float AttackTime;
	int AttackIndex;
	int MaxAttacks = 3;

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

		if (!CrystalSieger.bIntroAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CrystalSieger.bSiegerEnabled)
			return true;

		if (!CrystalSieger.bIntroAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttackTime = Time::GameTimeSeconds;
		AttackIndex = 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > AttackTime)
		{
			if (AttackIndex > MaxAttacks)
			{
				CrystalSieger.ActivatePhaseOne();
				return;
			}

			switch(AttackIndex)
			{
				case 1:
					SideSpiralAttacks();
					break;
				case 2:
					HorizontalLineAttacks();
					break;
				case 3:
					CircleAttacks();
					break;
			}

			AttackIndex++;
		}
	}

	void CircleAttacks()
	{
		float Delay = 0;
		
		for (ACrystalSiegeLineAttackActor Attack : CrystalSieger.CircleLineAttackActors)
		{
			Attack.FireAttack(Delay);
			Delay += 0.5;
		}

		AttackTime = Time::GameTimeSeconds + 3.0;
	}
	
	void SideSpiralAttacks()
	{
		CrystalSieger.LineAttackActors[0].FireAttack();
		CrystalSieger.LineAttackActors[CrystalSieger.LineAttackActors.Num() - 1].FireAttack(4.0);
		AttackTime = Time::GameTimeSeconds + 7.0;
	}

	void HorizontalLineAttacks()
	{
		float Delay = 0;
		
		for (ACrystalSiegeLineAttackActor Attack : CrystalSieger.HorizontalLineAttackActors)
		{
			Attack.FireAttack(Delay);
			Delay += 0.2;
		}

		AttackTime = Time::GameTimeSeconds + Delay;
	}

	void MiddleAttacks()
	{
		CrystalSieger.LineAttackActors[1].FireAttack();
		CrystalSieger.LineAttackActors[2].FireAttack(0.75);
		CrystalSieger.LineAttackActors[3].FireAttack(1.5);
		CrystalSieger.LineAttackActors[4].FireAttack(2.25);
		CrystalSieger.LineAttackActors[5].FireAttack(3.0);
		AttackTime = Time::GameTimeSeconds + 4.5;
	}

	void MiddleAttacks2()
	{
		CrystalSieger.LineAttackActors[5].FireAttack();
		CrystalSieger.LineAttackActors[2].FireAttack();

		CrystalSieger.LineAttackActors[4].FireAttack(1.5);
		CrystalSieger.LineAttackActors[3].FireAttack(1.5);

		CrystalSieger.LineAttackActors[1].FireAttack(3);
		CrystalSieger.LineAttackActors[3].FireAttack(3);
		CrystalSieger.LineAttackActors[5].FireAttack(3);
		AttackTime = Time::GameTimeSeconds + 4.5;
	}
};