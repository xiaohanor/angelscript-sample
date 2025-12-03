class UEnforcerRocketLauncherComponent : UBasicAINetworkedProjectileLauncherComponent
{
	FBasicAIProjectilePrime OnPrimeProjectile;
	UBasicAIProjectileComponent PrimedProjectile;

	UBasicAIProjectileComponent Launch(AHazeActor Target)
	{
		UBasicAIProjectileComponent Projectile = PrimedProjectile;
		if (PrimedProjectile == nullptr)
			Projectile = SpawnProjectile();

		Projectile.Launcher = Wielder;
		Projectile.Owner.DetachRootComponentFromParent(true);
		Projectile.Launch(FVector::ZeroVector);
		PrimedProjectile = nullptr;
		LastLaunchedProjectile = Projectile;
		OnLaunchProjectile.Broadcast(Projectile);

		AEnforcerRocketLauncherProjectile Rocket = Cast<AEnforcerRocketLauncherProjectile>(Projectile.Owner);
		Rocket.Target = Target;

		return Projectile;
	} 

	UBasicAIProjectileComponent Prime()
	{
		if (PrimedProjectile != nullptr)
			return PrimedProjectile;

		PrimedProjectile = SpawnProjectile();
		PrimedProjectile.Launcher = Wielder;
		PrimedProjectile.LaunchingWeapon = this;	
		PrimedProjectile.Prime();
		PrimedProjectile.Owner.AttachRootComponentTo(this, NAME_None, EAttachLocation::KeepWorldPosition);
		OnPrimeProjectile.Broadcast(PrimedProjectile);
		return PrimedProjectile;
	}

	UFUNCTION(BlueprintPure)
	AHazeActor GetWeaponActor() const property
	{
		return GetLauncherActor();
	}
}