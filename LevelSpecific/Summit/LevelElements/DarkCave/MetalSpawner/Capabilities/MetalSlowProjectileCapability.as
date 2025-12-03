class UMetalSlowProjectileCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitDarkCaveMetalSlowProjectile Projectile;

	float TargetDirectionSpeed = 2.0;
	float TargetMoveSpeed = 1200.0;
	float TargetSlowDownSpeed = 700.0;

	float DirectionAccelTime = 20.0;
	float MoveAccelTime = 2.0;

	FHazeAcceleratedFloat AccelDirectionSpeed;
	FHazeAcceleratedFloat AccelMoveSpeed;

	FHazeAcceleratedVector AccelDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Projectile = Cast<ASummitDarkCaveMetalSlowProjectile>(Owner);

		AccelDirectionSpeed.SnapTo(15.0);

		AccelMoveSpeed.SnapTo(TargetMoveSpeed / 8);
		AccelDirection.SnapTo(Projectile.ActorForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
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
		FVector TargetDir = (Projectile.Target.ActorLocation - Projectile.ActorLocation).GetSafeNormal();

		if (Projectile.Target.GetDistanceTo(Projectile) > Projectile.SlowDownRadius)
			AccelMoveSpeed.AccelerateTo(TargetMoveSpeed, MoveAccelTime, DeltaTime);
		else
			AccelMoveSpeed.AccelerateTo(TargetSlowDownSpeed, MoveAccelTime, DeltaTime);

		AccelDirectionSpeed.AccelerateTo(TargetDirectionSpeed, DirectionAccelTime, DeltaTime);
		AccelDirection.AccelerateTo(TargetDir, AccelDirectionSpeed.Value, DeltaTime);	
		FVector NormalizedForwardDirection = AccelDirection.Value.GetSafeNormal();

		Projectile.ActorLocation += NormalizedForwardDirection * AccelMoveSpeed.Value * DeltaTime;
		Projectile.ActorRotation = NormalizedForwardDirection.Rotation();

		//Should trace for collisions

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsPlayerDead())
			{
				if (Player == Projectile.Target)
					Projectile.Target = Player.OtherPlayer;
				
				continue;
			}

			if (Player.GetDistanceTo(Projectile) < Projectile.DamageRadius)
			{
				Player.DamagePlayerHealth(0.9);
				Projectile.ProjectileImpact();
			}
		}
	}
};