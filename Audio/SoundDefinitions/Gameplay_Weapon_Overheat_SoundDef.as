UCLASS(Abstract)
class UGameplay_Weapon_Overheat_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TriggerOnShoot(FGameplayWeaponParams GameplayWeaponParams){}

	UFUNCTION(BlueprintEvent)
	void TriggerOverheated(FGameplayWeaponOverheatParams GameplayWeaponOverheatParams){}

	/* END OF AUTO-GENERATED CODE */

}

USTRUCT()
struct FGameplayWeaponOverheatParams	
{
	UPROPERTY()
	float TimeUntilCooldown = 0;

	UPROPERTY()
	float CooldownTime = 0;
}