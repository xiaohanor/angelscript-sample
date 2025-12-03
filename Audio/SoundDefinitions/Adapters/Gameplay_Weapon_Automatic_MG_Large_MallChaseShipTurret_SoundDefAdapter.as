
class UGameplay_Weapon_Automatic_MG_Large_MallChaseShipTurret_SoundDefAdapter : USkylineMallChaseEnemyShipEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Fire Projectile*/
	UFUNCTION(BlueprintOverride)
	void OnFireProjectile(FGameplayWeaponParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;
		

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/* END OF AUTO-GENERATED CODE */

}