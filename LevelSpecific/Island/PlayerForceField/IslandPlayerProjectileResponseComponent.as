class UIslandPlayerProjectileResponseComponent : UIslandProjectileResponseComponent
{
	UIslandPlayerForceFieldUserComponent ForceFieldComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ForceFieldComp = UIslandPlayerForceFieldUserComponent::Get(Player);
		OnProjectileHit.AddUFunction(this, n"OnProjectileHit");
		OnLaserHit.AddUFunction(this, n"OnLaserHit");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnProjectileHit(FVector HitLocation, UIslandProjectileComponent ProjectileComp)
	{
		ForceFieldComp.TakeDamageBullet(ProjectileComp.Damage * 2, ProjectileComp.Damage, HitLocation);
	}

	UFUNCTION()
	private void OnLaserHit(FVector HitLocation, float DamagePerSecond, float DamageInterval)
	{
		ForceFieldComp.TakeDamageLaser(HitLocation, DamagePerSecond, DamageInterval);
	}
}