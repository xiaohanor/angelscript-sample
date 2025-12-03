class UCrystalSiegerExposedAttacksCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ACrystalSieger CrystalSieger;

	float AttackTime;
	float AttackRate = 2.0;

	bool bTargetPlayer;
	AHazePlayerCharacter TargetPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CrystalSieger = Cast<ACrystalSieger>(Owner);
		TargetPlayer = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CrystalSieger.bSiegerEnabled)
			return false;

		if (!CrystalSieger.bExposedAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CrystalSieger.bExposedAttack)
			return true;

		if (!CrystalSieger.bSiegerEnabled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
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
			AttackTime = Time::GameTimeSeconds + AttackRate;
			
			if (bTargetPlayer)
			{
				CrystalSieger.CrystalSiegerMortarArea.SpawnRandomMortar(CrystalSieger.MortarOrigin.WorldLocation, CrystalSieger);
			}
			else	
			{
				CrystalSieger.CrystalSiegerMortarArea.SpawnTargetedMortar(CrystalSieger.MortarOrigin.WorldLocation, TargetPlayer, CrystalSieger);
				TargetPlayer = TargetPlayer.OtherPlayer;
			}

			bTargetPlayer = !bTargetPlayer;
		}
	}
};