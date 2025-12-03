class UBattlefieldAlienGunnerFireCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BattlefieldAlienGunnerFireCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ABattlefieldAlienGunner Gunner;

	AHazePlayerCharacter TargetPlayer;
	FVector CurrentAimLocation;
	FVector EndAimLocation;
	float RightOffset = 100.0;
	float ZDownOffset = -750.0;
	float ZUpOffset = 450.0;
	float AimMoveSpeed = 400.0;

	float WaitDuration = 3.0;
	float WaitTime;

	float FireTime;
	float FireRate = 0.1;

	bool bFinishedAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Gunner = Cast<ABattlefieldAlienGunner>(Owner);
		TargetPlayer = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Gunner.bGunnerActive)
			return false;

		if (Time::GameTimeSeconds < WaitTime)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Gunner.bGunnerActive)
			return true;

		return bFinishedAttack;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bFinishedAttack = false;
		TargetPlayer = TargetPlayer.OtherPlayer;
		CurrentAimLocation = TargetPlayer.ActorLocation + FVector(0.0, 0.0, ZDownOffset);
		EndAimLocation = TargetPlayer.ActorLocation + FVector(0.0, 0.0, ZUpOffset);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentAimLocation = Math::VInterpConstantTo(CurrentAimLocation, EndAimLocation, DeltaTime, AimMoveSpeed);

		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + FireRate;
			FVector Dir = (CurrentAimLocation - Gunner.MeshRoot.WorldLocation).GetSafeNormal();
			FVector AimRightVector = Dir.CrossProduct(FVector::UpVector);

			FVector Dir1 = (CurrentAimLocation - (Gunner.MeshRoot.WorldLocation + AimRightVector * RightOffset)).GetSafeNormal();
			FVector Dir2 = (CurrentAimLocation - (Gunner.MeshRoot.WorldLocation + -AimRightVector * RightOffset)).GetSafeNormal();
			Gunner.ProjComp1.ManualSpawnProjectile(Dir1);
			Gunner.ProjComp2.ManualSpawnProjectile(Dir2);
		}

		if ((CurrentAimLocation - EndAimLocation).Size() < 1.0)
		{
			WaitTime = Time::GameTimeSeconds + WaitDuration;
			bFinishedAttack = true;
		}
	}
}