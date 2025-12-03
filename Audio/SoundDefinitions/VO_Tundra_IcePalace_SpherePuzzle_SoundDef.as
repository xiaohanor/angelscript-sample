
UCLASS(Abstract)
class UVO_Tundra_IcePalace_SpherePuzzle_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TundraTreeGuardianRangedShootProjectileVFX_OnFailDespawn(FTreeGuardianRangedShootProjectileDespawnParams TreeGuardianRangedShootProjectileDespawnParams){}

	UFUNCTION(BlueprintEvent)
	void TundraTreeGuardianRangedShootProjectileVFX_OnImpact(FTreeGuardianRangedShootProjectileImpactParams TreeGuardianRangedShootProjectileImpactParams){}

	UFUNCTION(BlueprintEvent)
	void TundraTreeGuardianRangedShootProjectileVFX_OnThrownByTreeGuardian(){}

	UFUNCTION(BlueprintEvent)
	void TundraTreeGuardianRangedShootProjectileVFX_OnBreakWaterSurface(){}

	UFUNCTION(BlueprintEvent)
	void TundraTreeGuardianRangedShootProjectileVFX_OnLaunched(){}

	UFUNCTION(BlueprintEvent)
	void TreeGuardianRangedShootProjectileSpawnerVFX_OnLaunchProjectile(FTundraTreeGuardianRangedShootProjectileSpawnerOnLaunchEffectParams TundraTreeGuardianRangedShootProjectileSpawnerOnLaunchEffectParams){}

	UFUNCTION(BlueprintEvent)
	void TreeGuardianRangedShootProjectileSpawnerVFX_OnSpawnProjectile(FTundraTreeGuardianRangedShootProjectileSpawnerOnSpawnEffectParams TundraTreeGuardianRangedShootProjectileSpawnerOnSpawnEffectParams){}

	UFUNCTION(BlueprintEvent)
	void TundraTreeGuardianRangedShootProjectileVFX_OnGrabbedByTreeGuardian(FTreeGuardianRangedShootProjectileGrabbedParams TreeGuardianRangedShootProjectileGrabbedParams){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION()
	void LinkToProjectileEvents(AHazeActor InProjectile)
	{
		EffectEvent::LinkActorToReceiveEffectEventsFrom(HazeOwner, InProjectile);
	}
}