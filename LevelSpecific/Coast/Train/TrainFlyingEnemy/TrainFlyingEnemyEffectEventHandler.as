UCLASS(Abstract)
class UTrainFlyingEnemyEffectEventHandler : UHazeEffectEventHandler
{
	// The enemy has started spiraling down into a crash
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartCrash() {}

	// The enemy has finished crashing and exploded
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CrashExplode() {}

	// The enemy has fired a projectile
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FireProjectile() {}

	UFUNCTION(BlueprintPure)
	ATrainFlyingEnemy GetTrainFlyingEnemy()
	{
		return Cast<ATrainFlyingEnemy>(Owner);
	}

	UFUNCTION()
	void AttachEffectToTrain(USceneComponent EffectComp)
	{
		ATrainFlyingEnemy Enemy = GetTrainFlyingEnemy();
		if (Enemy.Target.TargetCart != nullptr)
			EffectComp.AttachToComponent(Enemy.Target.TargetCart.Root, AttachmentRule = EAttachmentRule::KeepWorld);
		else if (Enemy.TrainCart != nullptr)
			EffectComp.AttachToComponent(Enemy.TrainCart.Root, AttachmentRule = EAttachmentRule::KeepWorld);
	}
}