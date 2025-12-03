class UNightQueenArmouredArmAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NightQueenArmouredArmAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ANightQueenArmouredArm ArmouredArm;

	float AttackActionTime;
	float AttackActionDuration = 1.5;

	float AttackRecoveryTime;
	float AttackRecoveryDuration = 2.0;

	float ImpactTime;
	float ImpactInterval = 0.35;

	bool bTriggeredImapct;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ArmouredArm = Cast<ANightQueenArmouredArm>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ArmouredArm.bIsPose)
			return false;

		if (ArmouredArm.TargetPlayers.Num() == 0)
			return false;

		if (GetDistanceToClosestTargetPlayer() > ArmouredArm.AttackRange)
			return false;

		if (Time::GameTimeSeconds < AttackRecoveryTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ArmouredArm.bIsPose)
			return true;

		if (ArmouredArm.TargetPlayers.Num() == 0)
			return true;

		if (GetDistanceToClosestTargetPlayer() > ArmouredArm.AttackRange)
			return true;

		if (Time::GameTimeSeconds > AttackActionTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ArmouredArm.SetAttackPose();
		AttackActionTime = Time::GameTimeSeconds + AttackActionDuration;
		ImpactTime = Time::GameTimeSeconds + ImpactInterval;
		bTriggeredImapct = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AttackRecoveryTime = Time::GameTimeSeconds + AttackRecoveryDuration;
		ArmouredArm.SetReadyPose();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > ImpactTime && !bTriggeredImapct)
		{
			bTriggeredImapct = true;
			Game::Mio.PlayWorldCameraShake(ArmouredArm.CameraShake, this, ArmouredArm.GroundImpactLocation.WorldLocation, 1000.0, 4000.0);
			Game::Zoe.PlayWorldCameraShake(ArmouredArm.CameraShake, this, ArmouredArm.GroundImpactLocation.WorldLocation, 1000.0, 4000.0);
		}
	}

	float GetDistanceToClosestTargetPlayer() const
	{
		if (ArmouredArm.GetClosestTargetPlayer() != nullptr)
			return (ArmouredArm.GetClosestTargetPlayer().ActorLocation - ArmouredArm.ActorLocation).Size();

		return 0.0; 
	}
}