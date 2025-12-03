
class UGameplay_Weapon_Pistol_IslandRed_ShieldBuster_SoundDefAdapter : UIslandRedBlueWeaponEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Called when the weapon is attached to the thigh*/
	UFUNCTION(BlueprintOverride)
	void OnWeaponAttachToThigh()
	{
		//SoundDef.();
	}

	/*Called when the weapon is attached to the hand*/
	UFUNCTION(BlueprintOverride)
	void OnWeaponAttachToHand()
	{
		//SoundDef.();
	}

	/*Called when the reload finishes*/
	UFUNCTION(BlueprintOverride)
	void OnReloadFinished()
	{
		//SoundDef.();
	}

	/*Called when the reload starts*/
	UFUNCTION(BlueprintOverride)
	void OnReloadStarted()
	{
		//SoundDef.();
	}

	/*Called when the grenade is shot from the weapon*/
	UFUNCTION(BlueprintOverride)
	void OnShootGrenade(FIslandRedBlueStickyGrenadeOnThrowParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/*Called when a bullet is shot from the weapon*/
	UFUNCTION(BlueprintOverride)
	void OnShootBullet(FIslandRedBlueWeaponOnShootParams InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}