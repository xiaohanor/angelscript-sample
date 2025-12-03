
class UGameplay_Projectile_Bullet_Impact_DropShipTurret_SoundDefAdapter : UControllableDropShipProjectileEffectEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Shot Impact*/
	UFUNCTION(BlueprintOverride)
	void ShotImpact(FControllableDropShipProjectileImpactParams InParams)
	{
		FProjectileSharedImpactAudioParams Params;
		Params.Location = InParams.ImpactLocation;

		//PrintToScreenScaled(""+Params.Location);
		Params.AudioPhysMat = InParams.AudioPhysMat;	

		SoundDef.Trigger_OnProjectileImpact(Params);
	}

	/* END OF AUTO-GENERATED CODE */

}