class UGemSpearMasterAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GemSpearMasterAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AGemSpearMaster SpearMaster;

	bool bSendToOppositePlayer;
	bool bIsAttacking;

	int AttackCount;
	int MaxAttackCount = 5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpearMaster = Cast<AGemSpearMaster>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SpearMaster.DetectPlayerComp.HasAvailablePlayers())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SpearMaster.DetectPlayerComp.HasAvailablePlayers())
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
		AttackCount = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bIsAttacking && Time::GameTimeSeconds > SpearMaster.WaitTime)
		{
			bIsAttacking = true;
		}
		
		if (Time::GameTimeSeconds > SpearMaster.MiniAttackTime && bIsAttacking)
		{
			SpearMaster.MiniAttackTime = Time::GameTimeSeconds + SpearMaster.MiniAttackDuration;
			AttackCount++;

			USceneComponent TargetComp;

			switch(AttackCount)
			{
				case 1:
					TargetComp = SpearMaster.LaunchPoint1;
					break;
				case 2:
					TargetComp = SpearMaster.LaunchPoint2;
					break;
				case 3:
					TargetComp = SpearMaster.LaunchPoint3;
					break;
				case 4:
					TargetComp = SpearMaster.LaunchPoint4;
					break;
				case 5:
					TargetComp = SpearMaster.LaunchPoint5;
					break;
			}


			if (SpearMaster.DetectPlayerComp.GetAvailablePlayers().Num() == 1)
			{
				SpearMaster.SpawnSword(SpearMaster.DetectPlayerComp.GetAvailablePlayers()[0], TargetComp);
			}
			else
			{
				AHazePlayerCharacter TargetPlayer = bSendToOppositePlayer ? SpearMaster.DetectPlayerComp.GetAvailablePlayers()[0] : SpearMaster.DetectPlayerComp.GetAvailablePlayers()[1];
				SpearMaster.SpawnSword(TargetPlayer, TargetComp);
			}


			if (AttackCount >= MaxAttackCount)
			{
				AttackCount = 0;
				bIsAttacking = false;
				bSendToOppositePlayer = !bSendToOppositePlayer;
				SpearMaster.WaitTime = Time::GameTimeSeconds + SpearMaster.WaitDuration;
			}
		}
	}
}