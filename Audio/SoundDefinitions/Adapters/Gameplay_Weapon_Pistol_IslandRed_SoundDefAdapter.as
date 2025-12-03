
class UGameplay_Weapon_Pistol_IslandRed_SoundDefAdapter : UIslandRedBlueWeaponEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Called when the bullet impacts something*/
	UFUNCTION(BlueprintOverride)
	void OnShootBullet(FIslandRedBlueWeaponOnShootParams InParams)
	{
		//SoundDef.(InParams);

		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = GetOverheatAlpha();
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/* END OF AUTO-GENERATED CODE */

}