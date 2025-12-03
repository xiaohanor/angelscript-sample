class UCrystalSiegerLineAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ACrystalSieger CrystalSieger;

	AHazePlayerCharacter TargetPlayer;

	float AttackRate = 3.0;
	float AttackTime;

	TPerPlayer<FVector> LastGroundImpact;

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

		if (!CrystalSieger.bLineAttacks)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CrystalSieger.bSiegerEnabled)
			return true;

		if (!CrystalSieger.bLineAttacks)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = Game::Zoe;
		AttackTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto MoveComp = UHazeMovementComponent::Get(TargetPlayer);
			if (MoveComp.IsOnWalkableGround())
				LastGroundImpact[Player] = MoveComp.GetGroundContact().ImpactPoint;
			// Debug::DrawDebugSphere(LastGroundImpact[Player], 150.0, 12, FLinearColor::Red, 5.0);
		}
		
		while (Time::GameTimeSeconds > AttackTime)
		{
			TargetPlayer = TargetPlayer.OtherPlayer;

			FVector TargetLoc = UHazeMovementComponent::Get(TargetPlayer).GetGroundContact().ImpactPoint;
			FRotator Rotation = (TargetLoc - CrystalSieger.LineAttackActor.ActorLocation).Rotation();  
			CrystalSieger.LineAttackActor.ActorRotation = Rotation;
			CrystalSieger.LineAttackActor.FireAttack();

			AttackTime = Time::GameTimeSeconds + AttackRate;
		}
	}
};