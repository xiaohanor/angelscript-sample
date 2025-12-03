struct FWeaponProjectileFlybyHitScanParams
{
	UPROPERTY()
	float Distance = 0.0;

	// 1 From front, 0 from side, -1 from back
	UPROPERTY()
	float NormalizedDirection = 1.0;

	UPROPERTY()
	AHazePlayerCharacter TargetPlayer = nullptr;
}

class UHitscanProjectileEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void HitscanProjectilePassby(FWeaponProjectileFlybyHitScanParams Params) {}
}


UCLASS(Abstract)
class UGameplay_Weapon_Projectile_Flybys_HitScan_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void HitscanProjectilePassby(FWeaponProjectileFlybyHitScanParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditDefaultsOnly)
	TPerPlayer<bool> bTriggerPerPlayer;
	default bTriggerPerPlayer[0] = true;
	default bTriggerPerPlayer[1] = true;

	UPROPERTY(BlueprintReadOnly)
	bool bIsPlayerProjectile = false;

	UFUNCTION(BlueprintPure)
	bool CanTriggerForPlayer(AHazePlayerCharacter Player)
	{
		return bTriggerPerPlayer[Player];
	}
}