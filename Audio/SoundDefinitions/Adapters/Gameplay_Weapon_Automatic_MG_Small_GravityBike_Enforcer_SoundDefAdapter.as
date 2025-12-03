
class UGameplay_Weapon_Automatic_MG_Small_GravityBike_Enforcer_SoundDefAdapter : UGravityBikeSplineEnforcerEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Death*/
	UFUNCTION(BlueprintOverride)
	void OnDeath()
	{
		//SoundDef.();
	}

	/*On Fire Trace Impact*/
	UFUNCTION(BlueprintOverride)
	void OnFireTraceImpact(FGravityBikeSplineEnforcerFireEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FGravityBikeSplineEnforcerFireEventData InParams)
	{
		FGameplayWeaponParams Params;
		Params.MagazinSize = 1;
		Params.ShotsFiredAmount = 1;

		SoundDef.TriggerOnShotFired(Params);
	}

	/* END OF AUTO-GENERATED CODE */

}