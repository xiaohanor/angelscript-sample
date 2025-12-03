
class UGameplay_Weapon_NPC_MeltdownBossPhaseTwoSpaceShipMissile_Projectile_Impact_SoundDefAdapter : UMeltdownBossPhaseTwoSpaceShipEffectHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */


	/*Shot Impact*/
	UFUNCTION(BlueprintOverride)
	void ShotImpact(FMeltdownBossPhaseTwoSpaceShipShotImpactParams InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.HitActor = nullptr;
		ImpactParams.Location = InParams.ImpactLocation;

		const FVector ToBullet = (InParams.MuzzleLocation - ImpactParams.Location).GetSafeNormal();
		ImpactParams.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(ToBullet, InParams.ImpactNormal);
		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/* END OF AUTO-GENERATED CODE */

}