class ULightProjectileLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(LightProjectile::Tags::LightProjectile);
	default CapabilityTags.Add(LightProjectile::Tags::LightProjectileLaunch);

	default TickGroupOrder = 100;

	ULightProjectileUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	float LastLaunchTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightProjectileUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.ChargedProjectiles.Num() == 0)
			return false;

		if (UserComp.bIsCharging)
			return false;

		if (!AimComp.IsAiming(UserComp))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.ChargedProjectiles.Num() == 0)
			return true;

		if (UserComp.bIsCharging)
			return true;

		if (!AimComp.IsAiming(UserComp))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastLaunchTime = -LightProjectile::LaunchInterval;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GetGameTimeSince(LastLaunchTime) >= LightProjectile::LaunchInterval)
		{
			auto TargetData = UserComp.GetAimTargetData();
			for (int i = 0; i < 2; ++i)
			{
				auto Projectile = UserComp.ChargedProjectiles[0];
				const FVector ToTarget = (TargetData.WorldLocation - Projectile.ActorLocation);
				const FVector SlingDirection = (Projectile.ActorLocation - UserComp.GetSpineTransform().Location);

				Projectile.Launch(
					ToTarget.GetSafeNormal() * 3000.0,
					TargetData,
					UProjectileProximityManagerComponent::Get(Player)
				);
				Projectile.MovementComp.AdjustmentVelocity = SlingDirection.GetSafeNormal() * 2000.0;

				UserComp.ChargedProjectiles.RemoveAt(0);
			}
			LastLaunchTime = Time::GameTimeSeconds;
		}
	}
}