
struct FAbilityProjectileImpactReboundParams
{
	UPROPERTY()
	float Intensity;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat;
}

struct FAbilityProjectileImpactParams
{
	UPROPERTY()
	float Intensity;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat;
}

UCLASS(Abstract)
class UGameplay_Ability_Projectile_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityProjectileActivated(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityProjectileShoot(FAbilityShootParams AbilityShootParams){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityProjectileImpactRebound(FAbilityProjectileImpactReboundParams AbilityProjectileImpactReboundParams){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityProjectileImpact(FAbilityProjectileImpactParams AbilityProjectileImpactParams){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityProjectileFadeOut(){}

	/* END OF AUTO-GENERATED CODE */
}