class UCoastContainerTurretWeaponDamageComponent : UActorComponent
{
	UBasicAIHealthComponent HealthComp;
	UCoastShoulderTurretGunResponseComponent ShoulderTurretResponseComp;
	UCoastContainerTurretSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
		ShoulderTurretResponseComp = UCoastShoulderTurretGunResponseComponent::GetOrCreate(Owner);
		ShoulderTurretResponseComp.OnBulletHit.AddUFunction(this, n"OnBulletHit");
		Settings = UCoastContainerTurretSettings::GetSettings(Cast<AHazeActor>(Owner));
		Owner.AddActorDisable(this);
		OnRespawn();
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Owner.RemoveActorDisable(this);
	}

	UFUNCTION()
	private void OnBulletHit(FCoastShoulderTurretBulletHitParams Params)
	{
		HealthComp.TakeDamage(Params.Damage * Settings.DamageFactor, EDamageType::Projectile, Params.PlayerInstigator);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		UCoastContainerTurretEffectHandler::Trigger_OnDeath(Cast<AHazeActor>(Owner));
	}

}
