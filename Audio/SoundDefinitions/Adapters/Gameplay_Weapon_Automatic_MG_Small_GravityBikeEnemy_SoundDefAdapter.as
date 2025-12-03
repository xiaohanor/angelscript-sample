
class UGameplay_Weapon_Automatic_MG_Small_GravityBikeEnemy_SoundDefAdapter : UGravityBikeSplineBikeEnemyDriverPistolEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Pistol Fire Trace Impact*/
	UFUNCTION(BlueprintOverride)
	void OnPistolFireTraceImpact(FGravityBikeSplineBikeEnemyDriverPistolFireEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Pistol Fire*/
	UFUNCTION(BlueprintOverride)
	void OnPistolFire(FGravityBikeSplineBikeEnemyDriverPistolFireEventData InParams)
	{
		FGameplayWeaponParams Params;
		Params.MagazinSize = 1;
		Params.ShotsFiredAmount = 1;

		SoundDef.TriggerOnShotFired(Params);

		//PrintToScreenScaled("OnShotFired - GravityBikeEnemy", 1);
	}

	/* END OF AUTO-GENERATED CODE */

}