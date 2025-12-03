class ULightProjectileChargeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(LightProjectile::Tags::LightProjectile);
	default CapabilityTags.Add(LightProjectile::Tags::LightProjectileCharge);

	default TickGroupOrder = 90;

	ULightProjectileUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	float LastSpawnTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightProjectileUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.ChargedProjectiles.Num() > 0)
			return false;

		if (!AimComp.IsAiming(UserComp))
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AimComp.IsAiming(UserComp))
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.bIsCharging = true;
		LastSpawnTime = -LightProjectile::SpawnInterval;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bIsCharging = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FTransform SpineTransform = UserComp.GetSpineTransform();

		// Translate and rotate projectiles
		for (int i = 0; i < UserComp.ChargedProjectiles.Num(); ++i)
		{
			auto Projectile = UserComp.ChargedProjectiles[i];

			const FVector Offset = UserComp.GetWingDirection(i) * UserComp.GetWingLength(i);
			const FVector Location = SpineTransform.Location + Offset;

			Projectile.ActorLocation = Math::Lerp(Projectile.ActorLocation, Location, DeltaTime * 12.0);
			Projectile.ActorRotation = SpineTransform.Rotation.Rotator();
		}

		if (!UserComp.IsFullyCharged() && Time::GetGameTimeSince(LastSpawnTime) >= LightProjectile::SpawnInterval)
		{
			for (int i = 0; i < 2; ++i)
			{
				auto Projectile = UserComp.SpawnProjectile(
					SpineTransform.Location,
					SpineTransform.Rotation.Rotator()
				);
				Projectile.Activate();
				
				UserComp.ChargedProjectiles.Add(Projectile);
			}

			LastSpawnTime = Time::GameTimeSeconds;
		}
	}
}