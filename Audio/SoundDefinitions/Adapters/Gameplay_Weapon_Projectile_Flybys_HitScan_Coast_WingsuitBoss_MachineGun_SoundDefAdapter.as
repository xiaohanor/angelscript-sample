
class UGameplay_Weapon_Projectile_Flybys_HitScan_Coast_WingsuitBoss_MachineGun_SoundDefAdapter : UWingsuitBossEffectHandler
{

	UGameplay_Weapon_Projectile_Flybys_HitScan_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Flybys_HitScan_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Machine Gun Bullet Impact*/
	UFUNCTION(BlueprintOverride)
	void OnMachineGunBulletImpact(FWingsuitMachineGunBulletImpactEffectParams InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Shoot Machine Gun Bullet*/
	UFUNCTION(BlueprintOverride)
	void OnShootMachineGunBullet(FWingsuitShootMachineGunBulletEffectParams InParams)
	{
		for(auto Player : Game::Players)
		{
			FVector ToPlayer = (Player.ActorLocation - InParams.MuzzleLocation).GetSafeNormal();
			float ShotDot = InParams.Direction.DotProduct(ToPlayer);	
			if(ShotDot >= 0.8)
			{
				const FVector ShotDir = InParams.Direction;
				const FVector PlayerCameraForward = Player.ControlRotation.ForwardVector;
				const float NormalizedDirectionValue = PlayerCameraForward.DotProduct(ShotDir) * -1;
				FVector ProjectedPassbyLocation = Math::ClosestPointOnInfiniteLine(InParams.MuzzleLocation, InParams.Direction, Player.ActorLocation);

				FWeaponProjectileFlybyHitScanParams Params;
				Params.TargetPlayer = Player;
				Params.Distance = Math::Saturate(ProjectedPassbyLocation.Distance(Player.ActorLocation) / 1000);
				Params.NormalizedDirection = NormalizedDirectionValue;

				//UHitscanProjectileEffectEventHandler::Trigger_HitscanProjectilePassby(Cast<AHazeActor>(CarEnemy), Params);

				SoundDef.HitscanProjectilePassby(Params);

				//Print("Projectile", 1.f);
			}

		}
		
	}

	/*When the boss shoots a mine*/
	UFUNCTION(BlueprintOverride)
	void OnShootMine()
	{
		//SoundDef.();
	}

	/*When the boss shoots a mine*/
	UFUNCTION(BlueprintOverride)
	void OnShootAirMine()
	{
		//SoundDef.();
	}

	/*The enemy has fired a multi rocket (5 rockets towards the player)*/
	UFUNCTION(BlueprintOverride)
	void OnShootMultiRocket()
	{
		//SoundDef.();
	}

	/*The enemy has fired a single rocket.*/
	UFUNCTION(BlueprintOverride)
	void OnShootRocket()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

}