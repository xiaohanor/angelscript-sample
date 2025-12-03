class UDarkProjectileLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(DarkProjectile::Tags::DarkProjectile);
	default CapabilityTags.Add(DarkProjectile::Tags::DarkProjectileLaunch);

	default TickGroupOrder = 100;

	UDarkProjectileUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	float LastLaunchTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkProjectileUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.ChargedProjectiles.Num() == 0)
			return false;

		if (IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.ChargedProjectiles.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastLaunchTime = -DarkProjectile::LaunchInterval;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GetGameTimeSince(LastLaunchTime) >= DarkProjectile::LaunchInterval)
		{
			auto TargetData = UserComp.GetAimTargetData();
			auto Projectile = UserComp.ChargedProjectiles[0];
			const FVector Direction = (TargetData.WorldLocation - Projectile.ActorLocation).GetSafeNormal();

			Projectile.Launch(
				Direction.GetSafeNormal() * 2500.0,
				TargetData,
				UProjectileProximityManagerComponent::Get(Player)
			);
			Projectile.MovementComp.AdjustmentVelocity = Player.MovementWorldUp * 1000.0;
			UserComp.ChargedProjectiles.RemoveAt(0);

			LastLaunchTime = Time::GameTimeSeconds;
		}

		for (int i = 0; i < UserComp.ChargedProjectiles.Num(); ++i)
		{
			auto Projectile = UserComp.ChargedProjectiles[i];

			if (Projectile == nullptr)
				continue;
			
			Projectile.ActorRotation = Math::RInterpTo(Projectile.ActorRotation, Player.ViewRotation, DeltaTime, 12.0);
		}
	}
}