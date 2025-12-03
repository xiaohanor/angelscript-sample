
class UGameplay_Weapon_Automatic_RocketLauncher_MeltdownBossPhaseThree_Executioner_SoundDefAdapter : UMeltdownBossPhaseThreeLavaMoleEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	AMeltdownBossPhaseThreeLavaMole MeltdownLavaMole;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MeltdownLavaMole = Cast<AMeltdownBossPhaseThreeLavaMole>(SoundDef.HazeOwner);
	}

	/* AUTO-GENERATED CODE  */

	/*Impact*/
	UFUNCTION(BlueprintOverride)
	void Impact(FMeltdownBossPhaseThreeLavaMoleImpactParams InParams)
	{
		MeltdownLavaMole.ExplosionSoundDef.SpawnSoundDefOneshot(this, FTransform(InParams.ImpactLocation));
	}

	/*Spawn*/
	UFUNCTION(BlueprintOverride)
	void Spawn()
	{
		FGameplayWeaponParams Params;
		SoundDef.TriggerOnShotFired(Params);
	}

	/* END OF AUTO-GENERATED CODE */

}