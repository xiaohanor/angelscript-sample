class USkylineSentryBossMortarStateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;


	ASKylineSentryBoss Boss;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASKylineSentryBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.BossState == EBossState::DefenseSystem1)
			return true;

		if(Boss.BossState == EBossState::DefenseSystem3)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.BossState == EBossState::DefenseSystem1)
			return false;

		if(Boss.BossState == EBossState::DefenseSystem3)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		Boss.TimeToMortarAttack = Time::GameTimeSeconds + 3;

		// TimeToActivateWeapon = Time::GameTimeSeconds + WeaponActivationCooldown;

		// AreaIndex = 0;
		// float Distance = 0;

		// for(int i = 0; i < Boss.MortarAreas.Num(); i++)
		// {
		// 	if(i == 0 || Distance > (Game::Zoe.ActorLocation - Boss.MortarAreas[i].ActorLocation).Size())
		// 	{
		// 		Distance = (Game::Zoe.ActorLocation - Boss.MortarAreas[i].ActorLocation).Size();
		// 		AreaIndex = i;
		// 	}
		// }

		// if(AreaIndex >= Boss.MortarAreas.Num() / 2)
		// {
		// 	bReverseAttack = true;

		// 	for(int i = Boss.MortarAreas.Num() - 1; i > AreaIndex; i--)
		// 	{
		// 		Boss.MortarAreas[i].AllAttack();
		// 	}

		// }
		// else
		// {
		// 	bReverseAttack = false;

		// 	for(int i = 0; i < AreaIndex; i++)
		// 	{
		// 		Boss.MortarAreas[i].AllAttack();
		// 	}
		// }
		

	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Boss.bActiveMortarAttack)
			return;
		
		if(Boss.TimeToMortarAttack > Time::GameTimeSeconds)
			return;

		Boss.bActiveMortarAttack = true;

		// if(TimeToActivateWeapon > Time::GameTimeSeconds)
		// 	return;
	
		// TimeToActivateWeapon = Time::GameTimeSeconds + WeaponActivationCooldown;
		// Boss.MortarAreas[AreaIndex].AllAttack();
		


		// if(bReverseAttack)
		// 	AreaIndex--;
		// else
		// 	AreaIndex++;

		// if(AreaIndex == -1 || AreaIndex == Boss.MortarAreas.Num())
		// 	return;
	}
};