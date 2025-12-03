class USanctuarySnakeShootCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default CapabilityTags.Add(n"SanctuarySnake");

	USanctuarySnakeSettings Settings;
	ASanctuarySnake Snake;

	USanctuarySnakeComponent SanctuarySnakeComponent;

	float ShootInterval = 0.2;
	float ShootTimer = 0.0;
	int ShootNum = 4;
	int ShotProjectiles = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);
		Settings = USanctuarySnakeSettings::GetSettings(Owner);
		Snake = Cast<ASanctuarySnake>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SanctuarySnakeComponent.bShootAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SanctuarySnakeComponent.bShootAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"SanctuarySnakeRiderMovement", this);

		ShotProjectiles = 0;
		ShootTimer = 0;
		SanctuarySnakeComponent.OnShoot.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"SanctuarySnakeRiderMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ShootTimer -= DeltaTime;
		if (ShootTimer <= 0)
			Shoot();
	
		if (ShotProjectiles >= ShootNum)
			SanctuarySnakeComponent.bShootAttack = false;
	}

	void Shoot()
	{
		ShotProjectiles += 1;
		ShootTimer = ShootInterval;
		FVector ToPlayer = (Game::Mio.ActorCenterLocation - Snake.ProjectileLauncherComponent.WorldLocation).GetSafeNormal();
		FVector RandDirection =	Math::GetRandomConeDirection(ToPlayer, 0.12);

		// TODO: Needs networking
		Snake.ProjectileLauncherComponent.Launch(RandDirection * 2500.0);
	//	SanctuarySnakeComponent.bShootAttack = false;
	}
}