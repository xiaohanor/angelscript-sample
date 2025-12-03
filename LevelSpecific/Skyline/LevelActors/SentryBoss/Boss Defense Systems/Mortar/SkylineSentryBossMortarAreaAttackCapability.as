class USkylineSentryBossMortarAreaAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;



	ASKylineSentryBoss Boss;

	int AreaIndex = 0;
	
	float MortarAttackCooldown = 16;
	float AreaActivationCooldown = 3;
	float TimeToActivateArea;
	
	bool bFullAreaAttack;
	bool bReverseAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASKylineSentryBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.bActiveMortarAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.bActiveMortarAttack)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

		AreaIndex = 0;
		float Distance = 0;

		for(int i = 0; i < Boss.MortarAreas.Num(); i++)
		{
			if(i == 0 || Distance > (Game::Zoe.ActorLocation - Boss.MortarAreas[i].ActorLocation).Size())
			{
				Distance = (Game::Zoe.ActorLocation - Boss.MortarAreas[i].ActorLocation).Size();
				AreaIndex = i;
			}
		}

		if(AreaIndex >= Math::IntegerDivisionTrunc(Boss.MortarAreas.Num(), 2))
		{
			bReverseAttack = true;

			for(int i = Boss.MortarAreas.Num() - 1; i > AreaIndex; i--)
			{
				Boss.MortarAreas[i].AllAttack();
			}

		}
		else
		{
			bReverseAttack = false;

			for(int i = 0; i < AreaIndex; i++)
			{
				Boss.MortarAreas[i].AllAttack();
			}
		}
			

	}



	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TimeToActivateArea > Time::GameTimeSeconds)
			return;
	
		TimeToActivateArea = Time::GameTimeSeconds + AreaActivationCooldown;
		Boss.MortarAreas[AreaIndex].RowAttack(bReverseAttack, AreaActivationCooldown);

		if(bReverseAttack)
			AreaIndex--;
		else
			AreaIndex++;

		if(AreaIndex == 0 || AreaIndex == Boss.MortarAreas.Num() - 1) 
		{
			Boss.TimeToMortarAttack = Time::GameTimeSeconds + MortarAttackCooldown;
			Boss.bActiveMortarAttack = false;
		}

		Print("Active: " + Boss.bActiveMortarAttack);
	}
};