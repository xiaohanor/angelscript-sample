
class UGameplay_Weapon_Automatic_Cannon_Prison_BallBossRocket_SoundDefAdapter : UPinballBossRocketEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Reset*/
	UFUNCTION(BlueprintOverride)
	void OnReset()
	{
		//SoundDef.();
	}

	/*On Hit*/
	UFUNCTION(BlueprintOverride)
	void OnHit()
	{
		//SoundDef.();
	}

	/*On Released*/
	UFUNCTION(BlueprintOverride)
	void OnReleased()
	{
		//SoundDef.();
	}

	/*On Launched*/
	UFUNCTION(BlueprintOverride)
	void OnLaunched()
	{
		FGameplayWeaponParams Params;
		SoundDef.TriggerOnShotFired(Params);
	}

	/* END OF AUTO-GENERATED CODE */

}