class UDarkProjectileChargeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(DarkProjectile::Tags::DarkProjectile);
	default CapabilityTags.Add(DarkProjectile::Tags::DarkProjectileCharge);

	default TickGroupOrder = 90;

	UDarkProjectileUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	TArray<ADarkProjectileActor> ChargingProjectiles;

	float LastSpawnTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkProjectileUserComponent::Get(Owner);
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
			return true;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastSpawnTime = -DarkProjectile::SpawnInterval;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Move charging projectiles over to user component
		//  as fully charged ones, indicates that they're ready
		//  for being launched
		for (int i = 0; i < ChargingProjectiles.Num(); ++i)
			UserComp.ChargedProjectiles.Add(ChargingProjectiles[i]);

		ChargingProjectiles.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ChargingProjectiles.Num() < DarkProjectile::NumProjectiles &&
			Time::GetGameTimeSince(LastSpawnTime) >= DarkProjectile::SpawnInterval)
		{
			LastSpawnTime = Time::GameTimeSeconds;

			auto Projectile = UserComp.SpawnProjectile(
				Player.ActorCenterLocation
			);
			Projectile.Activate();

			ChargingProjectiles.Add(Projectile);
		}

		for (int i = 0; i < ChargingProjectiles.Num(); ++i)
		{
			auto Projectile = ChargingProjectiles[i];
			
			const FVector Location = GetOrbitLocation(i);
			const FRotator Rotation = (Location - Projectile.ActorLocation).Rotation();

			Projectile.ActorLocation = Math::Lerp(Projectile.ActorLocation, Location, DeltaTime * 12.0);
			Projectile.ActorRotation = Rotation;
		}
	}

	private FVector GetOrbitLocation(int Index)
	{
		const float Radius = 50.0;
		const float AngleStep = TWO_PI / DarkProjectile::NumProjectiles;
		const float HalfArcAngle = AngleStep * (DarkProjectile::NumProjectiles - 1) * 0.5 + Time::GameTimeSeconds * 4.0;
		const FTransform Origin = UserComp.GetSocketTransform();
		
		FVector Offset(
			Math::Sin(Index * AngleStep - HalfArcAngle) * (Radius * 0.5),
			Math::Sin(Index * AngleStep - HalfArcAngle) * (Radius * 0.5),
			Math::Cos(Index * AngleStep - HalfArcAngle) * (Radius * 0.5),
		);

		Offset += (Origin.Rotation.UpVector + Origin.Rotation.RightVector) * 
			Math::Sin((Time::GameTimeSeconds + Index * 50.0) * 5.0) * 20.0;

		return Origin.Location + Offset;
	}
}