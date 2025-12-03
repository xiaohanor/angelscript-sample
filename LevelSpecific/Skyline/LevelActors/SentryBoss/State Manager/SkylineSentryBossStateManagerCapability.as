class USkylineSentryBossStateManagerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASKylineSentryBoss Boss;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASKylineSentryBoss>(Owner);

		for(ASkylineSentryBossForceFieldEmitter Emitters : Boss.ForceFieldEmitters)
			Emitters.OnEmitterDestroy.AddUFunction(this, n"OnEmitterDestroy");

	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		if(Boss.bIsPlayerOnBoss)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.bIsPlayerOnBoss)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.BossState = EBossState::DefenseSystem1;

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}

	UFUNCTION()
	private void OnEmitterDestroy()
	{
		if(Boss.BossState == EBossState::DefenseSystem5)
		{
			Boss.BossState = EBossState::DefenseSystem1;
		}

		Boss.BossState = EBossState(int(Boss.BossState) + 1);

	}

};