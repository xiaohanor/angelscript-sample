struct FTrainFlyingEnemyProjectileSubmunitionParams
{
	UPROPERTY()
	UPrimitiveComponent Submunition;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	AHazeActor TargetTrainCart;

	FTrainFlyingEnemyProjectileSubmunitionParams(UPrimitiveComponent SubmunitionComp, FVector Loc, AHazeActor TrainCart)
	{
		Submunition = SubmunitionComp;
		Location = Loc;
		TargetTrainCart = TrainCart;
	}
}

UCLASS(Abstract)
class UTrainFlyingEnemyProjectileEffectEventHandler : UHazeEffectEventHandler
{
	// Triggered when submunition explodes
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SubmunitionImpactExplosion(FTrainFlyingEnemyProjectileSubmunitionParams Params) {}

	// Triggered when submunition fails to explode and just fizzles out
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SubmunitionMissed(FTrainFlyingEnemyProjectileSubmunitionParams Params) {}

	// Triggered when submunition launches
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SubmunitionLaunch(FTrainFlyingEnemyProjectileSubmunitionParams Params) {}

	// Triggered when main projectile breaks apart into submunitions
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeploySubmunitions() {}

	// Triggered when main projectile is launched
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launch() {}
}