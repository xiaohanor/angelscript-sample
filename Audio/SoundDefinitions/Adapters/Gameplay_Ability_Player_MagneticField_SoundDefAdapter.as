
class UGameplay_Ability_Player_MagneticField_SoundDefAdapter : UMagneticFieldEventHandler
{

	UGameplay_Ability_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Ability_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Stopped*/
	UFUNCTION(BlueprintOverride)
	void Stopped()
	{
		SoundDef.TriggerOnAbilityLoopStopped();
	}

	/*Finished Charging*/
	UFUNCTION(BlueprintOverride)
	void FinishedCharging()
	{
		SoundDef.TriggerOnAbilityShoot(FAbilityShootParams());
	}

	/*Charging*/
	UFUNCTION(BlueprintOverride)
	void Charging(FMagneticFieldChargingData InParams)
	{
		//SoundDef.(InParams);
	}

	/*Started Charging*/
	UFUNCTION(BlueprintOverride)
	void StartedCharging()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		SoundDef.AbilityPlayerOwner = Game::GetZoe();
	}

}