
class UGameplay_Weapon_Automatic_Cannon_Skyline_BossTank_SoundDefAdapter : USkylineBossTankMortarBallEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Explode*/
	UFUNCTION(BlueprintOverride)
	void OnExplode(FSkylineBossTankMortarBallOnExplodeEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FSkylineBossTankMortarBallOnImpactEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Shot Fired from Tank*/
	UFUNCTION(BlueprintOverride)
	void OnShotFiredFromTank()
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//PrintToScreen(f"Shoot - {Time::AudioTimeSeconds})", 10);
	}

	/*On Fired*/
	UFUNCTION(BlueprintOverride)
	void OnFired(FSkylineBossTankMortarBallOnFiredEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}