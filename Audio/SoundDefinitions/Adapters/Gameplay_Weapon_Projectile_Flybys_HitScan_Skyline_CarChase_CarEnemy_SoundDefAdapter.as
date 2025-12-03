
class UGameplay_Weapon_Projectile_Flybys_HitScan_Skyline_CarChase_CarEnemy_SoundDefAdapter : USkylineFlyingCarEnemyTurretEventHandler
{

	UGameplay_Weapon_Projectile_Flybys_HitScan_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Flybys_HitScan_SoundDef>(Outer);
	}
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	/* AUTO-GENERATED CODE  */

	/*On Hit*/
	UFUNCTION(BlueprintOverride)
	void OnHit(FSkylineFlyingCarEnemyTurretHitEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FSkylineFlyingCarEnemyTurretFireEventData InParams)
	{
		AHazePlayerCharacter Player = SkylineFlyingCarEnemy::GetDriverPlayer();
		FVector ToPlayer = (Player.ActorLocation - CarEnemy.TurretComp.GetCurrentMuzzleLocation()).GetSafeNormal();
		float ShotDot = CarEnemy.TurretComp.GetCurrentMuzzle().ForwardVector.DotProduct(ToPlayer);	
		if(ShotDot >= 0.8)
		{
			const FVector ShotDir = CarEnemy.ActorForwardVector;
			const FVector PlayerCameraForward = Player.ControlRotation.ForwardVector;
			const float NormalizedDirectionValue = PlayerCameraForward.DotProduct(ShotDir) * -1;
			FVector ProjectedPassbyLocation = Math::ClosestPointOnInfiniteLine(CarEnemy.ActorLocation, CarEnemy.ActorForwardVector, Player.ActorLocation);

			FWeaponProjectileFlybyHitScanParams Params;
			Params.TargetPlayer = Player;
			Params.Distance = Math::Saturate(ProjectedPassbyLocation.Distance(Player.ActorLocation) / 1000);
			Params.NormalizedDirection = NormalizedDirectionValue;

			//UHitscanProjectileEffectEventHandler::Trigger_HitscanProjectilePassby(Cast<AHazeActor>(CarEnemy), Params);

			SoundDef.HitscanProjectilePassby(Params);
		}
		
	}

	/* END OF AUTO-GENERATED CODE */

}