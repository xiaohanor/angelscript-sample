
UCLASS(Abstract)
class UGameplay_Character_Boss_Skyline_TripodMech_RocketBarrage_Projectile_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnUnspawn(){}

	UFUNCTION(BlueprintEvent)
	void OnImpact(FSkylineBossRocketBarrageOnImpactEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnLaunch(){}

	/* END OF AUTO-GENERATED CODE */

	ASkylineBossRocketBarrageProjectile RocketBarrage;
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		RocketBarrage = Cast<ASkylineBossRocketBarrageProjectile>(HazeOwner);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Projectile Travel Alpha"))
    float GetProjectileTravelAlpha()
    {
        const float DistSqrd = RocketBarrage.SpawnLocation.DistSquared(RocketBarrage.Target.Location);

		return Math::GetMappedRangeValueClamped(FVector2D(DistSqrd, 0.0), FVector2D(0.0, 1.0), RocketBarrage.ActorLocation.DistSquared(RocketBarrage.Target.Location));
    }

}