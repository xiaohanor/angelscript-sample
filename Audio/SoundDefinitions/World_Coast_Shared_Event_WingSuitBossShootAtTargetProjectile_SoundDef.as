
UCLASS(Abstract)
class UWorld_Coast_Shared_Event_WingSuitBossShootAtTargetProjectile_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnRocketFired(){}

	UFUNCTION(BlueprintEvent)
	void OnRocketExploded(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	TArray<FVector> ValidTargetLocations;

	UPROPERTY()
	AWingsuitBossShootAtTargetProjectile Projectile;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Projectile = Cast<AWingsuitBossShootAtTargetProjectile>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	bool HasValidTarget() const
	{
		for (const auto& ValidPos: ValidTargetLocations)
		{
			if (Projectile.TargetData.TargetLocation.DistSquared(ValidPos) < 100)
			{
				return true;
			}
		}

		return false;
	}
}