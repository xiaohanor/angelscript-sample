
class UGameplay_Weapon_Overheat_CopsGun_SoundDefAdapter : UScifiCopsGunEventHandler
{
	UGameplay_Weapon_Overheat_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Overheat_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Overheat*/
	UFUNCTION(BlueprintOverride)
	void OnOverheat(FScifiPlayerCopsGunOverheatData InParams)
	{
		FGameplayWeaponOverheatParams OverheatParams;
		OverheatParams.TimeUntilCooldown = InParams.TimeUntilWeStartTheCooldown;
		OverheatParams.CooldownTime = InParams.CooldownTime;

		SoundDef.TriggerOverheated(OverheatParams);
	}


	/*On Shoot*/
	UFUNCTION(BlueprintOverride)
	void OnShoot(FScifiPlayerCopsGunOnShootEventData OnShootData)
	{
		FGameplayWeaponParams ShootParams;
		ShootParams.OverheatAmount = OnShootData.OverheatAmount;
		ShootParams.OverheatMaxAmount = OnShootData.OverheatMaxAmount;

		SoundDef.TriggerOnShoot(ShootParams);		
	}

	/* END OF AUTO-GENERATED CODE */

}