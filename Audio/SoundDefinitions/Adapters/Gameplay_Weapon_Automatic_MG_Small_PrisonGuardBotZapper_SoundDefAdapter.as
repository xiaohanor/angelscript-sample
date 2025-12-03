

class UGameplay_Weapon_Automatic_MG_Small_PrisonGuardBotZapper_SoundDefAdapter : UPrisonGuardBotEffectHandler

{


	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property

	{

		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);

	}



	/* AUTO-GENERATED CODE  */



	/*On Shoot*/

	UFUNCTION(BlueprintOverride)

	void OnShoot(FPrisonGuardBotShootParams InParams)

	{

		FGameplayWeaponParams Params;
		Params.MagazinSize = 1;
		Params.ShotsFiredAmount = 1;

		SoundDef.TriggerOnShotFired(Params);

		//PrintToScreenScaled("OnShotFired - GravityBikeEnemy", 1);

	}



	/*On Zap Stop*/

	UFUNCTION(BlueprintOverride)

	void OnZapStop(FPrisonGuardBotZapParams InParams)

	{

		//SoundDef.(InParams);

	}



	/*On Zap Start*/

	UFUNCTION(BlueprintOverride)

	void OnZapStart(FPrisonGuardBotZapParams InParams)

	{

		//SoundDef.(InParams);

	}



	/*On Explode*/

	UFUNCTION(BlueprintOverride)

	void OnExplode()

	{

		//SoundDef.();

	}



	/*On Charge End*/

	UFUNCTION(BlueprintOverride)

	void OnChargeEnd()

	{

		//SoundDef.();

	}



	/*On Charge Start*/

	UFUNCTION(BlueprintOverride)

	void OnChargeStart()

	{

		//SoundDef.();

	}



	/*On Telegraph Charge*/

	UFUNCTION(BlueprintOverride)

	void OnTelegraphCharge()

	{

		//SoundDef.();

	}



	/*On Magnetic Burst Stunned End*/

	UFUNCTION(BlueprintOverride)

	void OnMagneticBurstStunnedEnd()

	{

		//SoundDef.();

	}



	/*On Magnetic Burst Stunned Start*/

	UFUNCTION(BlueprintOverride)

	void OnMagneticBurstStunnedStart()

	{

		//SoundDef.();

	}



	/* END OF AUTO-GENERATED CODE */



}