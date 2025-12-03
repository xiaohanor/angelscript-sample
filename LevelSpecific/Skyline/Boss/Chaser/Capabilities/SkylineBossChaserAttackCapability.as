class USkylineBossChaserAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineBossChaser Chaser;

	float FireTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Chaser = Cast<ASkylineBossChaser>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < Chaser.Settings.AttackCooldown)
			return false;

		if (!HasTargetInRange())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Chaser.Settings.AttackDuration)
			return true;

		if (!HasTargetInRange())
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
		if (Time::GameTimeSeconds > FireTime)
		{
			FVector ToTarget = Chaser.CurrentTarget.Get().ActorLocation - Chaser.ProjectileLauncherComp.WorldLocation;
			Chaser.ProjectileLauncherComp.Launch(ToTarget.SafeNormal * 20000.0 + Chaser.ActorVelocity, ToTarget.ToOrientationRotator());
			FireTime = Time::GameTimeSeconds + Chaser.Settings.AttackFireInterval;
		}
	}

	bool HasTargetInRange() const
	{
		if (Chaser.CurrentTarget.IsDefaultValue())
			return false;

		if (Owner.GetDistanceTo(Chaser.CurrentTarget.Get()) > Chaser.Settings.AttackRange)
			return false;

		return true;
	}
};