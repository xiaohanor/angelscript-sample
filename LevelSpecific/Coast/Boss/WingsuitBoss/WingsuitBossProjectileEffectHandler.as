struct FWingsuitBossProjectileSubmunitionParams
{
	UPROPERTY()
	UPrimitiveComponent Submunition;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	AHazeActor TargetTrainCart;

	FWingsuitBossProjectileSubmunitionParams(UPrimitiveComponent SubmunitionComp, FVector Loc, AHazeActor TrainCart)
	{
		Submunition = SubmunitionComp;
		Location = Loc;
		TargetTrainCart = TrainCart;
	}
}

UCLASS(Abstract)
class UWingsuitBossProjectileEffectEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AWingsuitBossProjectile ProjectileOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ProjectileOwner = Cast<AWingsuitBossProjectile>(Owner);
	}
	
	// Triggered when submunition explodes
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SubmunitionImpactExplosion(FWingsuitBossProjectileSubmunitionParams Params) {}

	// Triggered when submunition fails to explode and just fizzles out
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SubmunitionMissed(FWingsuitBossProjectileSubmunitionParams Params) {}

	// Triggered when submunition launches
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SubmunitionLaunch(FWingsuitBossProjectileSubmunitionParams Params) {}

	// Triggered when main projectile breaks apart into submunitions
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeploySubmunitions() {}

	// Triggered when main projectile is launched
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launch(FWingsuitBossProjectileLaunchParams Params) {}
}

struct FWingsuitBossProjectileLaunchParams
{
	UPROPERTY()
	UBasicAIProjectileLauncherComponent Launcher;
	UPROPERTY()
	FVector LaunchLocation;
}
