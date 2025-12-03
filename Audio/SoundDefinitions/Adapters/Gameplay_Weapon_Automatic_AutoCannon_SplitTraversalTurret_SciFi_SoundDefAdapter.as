
class UGameplay_Weapon_Automatic_AutoCannon_SplitTraversalTurret_SciFi_SoundDefAdapter : USplitTraversalControllableTurretEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Interaction Stopped*/
	UFUNCTION(BlueprintOverride)
	void OnInteractionStopped()
	{
		//SoundDef.();
	}

	/*On Interaction Started*/
	UFUNCTION(BlueprintOverride)
	void OnInteractionStarted()
	{
		//SoundDef.();
	}

	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire()
	{
		FGameplayWeaponParams Params;
		SoundDef.TriggerOnShotFired(Params);
	}

	/* END OF AUTO-GENERATED CODE */

}