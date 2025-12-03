class USanctuaryGhostProjectileAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SanctuaryGhost");
	default CapabilityTags.Add(n"SanctuaryGhostAttack");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryGhost Ghost;

	float DamageInterval = 0.25;
	float DamageTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ghost = Cast<ASanctuaryGhost>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 1.0)
			return false;

		if (Ghost.TargetPlayer == nullptr)
			return false;

		if (Ghost.TargetPlayer.IsPlayerDead())
			return false;

//		if (DeactiveDuration < 0.5)
//			return false;

		if (Ghost.GetDistanceTo(Ghost.TargetPlayer) > Ghost.AttackRange)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Ghost.ProjectileAttack();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};