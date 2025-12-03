
class UGameplay_Weapon_Rilfe_Turret_Skyline_SoundDefAdapter : USkylineSniperTurretAimingEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Shot Fired*/
	UFUNCTION(BlueprintOverride)
	void OnShotFired()
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/*SniperTurret stopped aiming (SkylineSniperAiming.OnStoppedAiming)*/
	UFUNCTION(BlueprintOverride)
	void OnStoppedAiming(FSkylineSniperTurretAimingEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*SniperTurret decided where to shoot and stopped changing its aiming (SkylineSniperTurretAiming.OnDecidedAiming)*/
	UFUNCTION(BlueprintOverride)
	void OnDecidedAiming(FSkylineSniperTurretAimingEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*SniperTurret started aiming (SkylineSniperAiming.OnStartedAiming)*/
	UFUNCTION(BlueprintOverride)
	void OnStartedAiming(FSkylineSniperTurretAimingEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}