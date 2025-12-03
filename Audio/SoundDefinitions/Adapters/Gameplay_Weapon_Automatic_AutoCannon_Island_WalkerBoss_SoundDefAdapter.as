
class UGameplay_Weapon_Automatic_AutoCannon_Island_WalkerBoss_SoundDefAdapter : UIslandWalkerEffectHandler
{
	AIslandWalkerHead WalkerHead;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerHead = Cast<AAIIslandWalker>(WalkerComp.Owner).GetHead();		
	}

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Suspension Cable Weaken*/
	UFUNCTION(BlueprintOverride)
	void OnSuspensionCableWeaken(FIslandWalkerCableEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Suspension Cable Break*/
	UFUNCTION(BlueprintOverride)
	void OnSuspensionCableBreak(FIslandWalkerCableEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Suspension Cable Latch On*/
	UFUNCTION(BlueprintOverride)
	void OnSuspensionCableLatchOn(FIslandWalkerCableEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Suspension Cable Start Moving*/
	UFUNCTION(BlueprintOverride)
	void OnSuspensionCableStartMoving(FIslandWalkerCableEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Cables Target Power Down*/
	UFUNCTION(BlueprintOverride)
	void OnCablesTargetPowerDown(FIslandWalkerCablesTargetEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Cables Target Power Up*/
	UFUNCTION(BlueprintOverride)
	void OnCablesTargetPowerUp(FIslandWalkerCablesTargetEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Neck Target Power Down*/
	UFUNCTION(BlueprintOverride)
	void OnNeckTargetPowerDown(FIslandWalkerNeckTargetEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Neck Target Power Up*/
	UFUNCTION(BlueprintOverride)
	void OnNeckTargetPowerUp(FIslandWalkerNeckTargetEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Leg Attack*/
	UFUNCTION(BlueprintOverride)
	void OnLegAttack(FIslandWalkerLegAttackEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*Splash attack landing*/
	UFUNCTION(BlueprintOverride)
	void OnSplashAttackLanded()
	{
		//SoundDef.();
	}

	/*Jump attack landing*/
	UFUNCTION(BlueprintOverride)
	void OnJumpAttackLanded(FIslandWalkerJumpAttackLandedEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*A minion was spawned (IslandWalker.OnSpawnedMinion)*/
	UFUNCTION(BlueprintOverride)
	void OnSpawnedMinion(FIslandWalkerSpawnedMinionEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*Laser beams resume after pausing from having crossed*/
	UFUNCTION(BlueprintOverride)
	void OnCrossedLasersResume()
	{
		//SoundDef.();
	}

	/*Laser beams crossed each other*/
	UFUNCTION(BlueprintOverride)
	void OnCrossedLasers()
	{
		//SoundDef.();
	}

	/*Laser stopped firing (IslandWalker.OnStoppedLaser)*/
	UFUNCTION(BlueprintOverride)
	void OnStoppedLaser()
	{
		//SoundDef.();

		Timer::ClearTimer(this, n"GattlingGunDelayAttack");
	}

	/*Laser started firing (IslandWalker.OnStartedLaser)*/
	UFUNCTION(BlueprintOverride)
	void OnStartedLaser(FIslandWalkerLaserEventData InParams)
	{
		//This is the gattling gun not a laser
		
		GattlingGunDelayAttack();
		GattlingGunShootTimer = Timer::SetTimer(this,n"GattlingGunDelayAttack", 0.09, true);

		//Print("GattlingShoot", 0.1f);
	}

	/*On Telegraph Laser*/
	UFUNCTION(BlueprintOverride)
	void OnTelegraphLaser(FIslandWalkerLaserEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*The owner died (IslandWalker.OnDeath)*/
	UFUNCTION(BlueprintOverride)
	void OnDeath()
	{
		//SoundDef.();
	}

	/*On Shell Explosion*/
	UFUNCTION(BlueprintOverride)
	void OnShellExplosion(FIslandWalkerShellExplosionEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

	int TriggerCount = 0;
	FTimerHandle GattlingGunShootTimer;

	UFUNCTION()
	void GattlingGunDelayAttack()
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.ShotsFiredAmount = 1.0;
		WeaponParams.MagazinSize = 1.0;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//Print("ShotFired", 1.f);

		// Check if we need to trigger flyby
		for(auto Player : Game::GetPlayers())
		{
			FVector ToPlayer = (Player.ActorLocation - WalkerHead.ActorLocation).GetSafeNormal();
			float ShotDot = WalkerHead.ActorForwardVector.DotProduct(ToPlayer);	
			if(ShotDot >= 0.8)
			{
				const FVector ShotDir = WalkerHead.ActorForwardVector;
				const FVector PlayerCameraForward = Player.ControlRotation.ForwardVector;
				const float NormalizedDirectionValue = PlayerCameraForward.DotProduct(ShotDir) * -1;
				FVector ProjectedPassbyLocation = Math::ClosestPointOnInfiniteLine(WalkerHead.ActorLocation, WalkerHead.ActorForwardVector, Player.ActorLocation);

				FWeaponProjectileFlybyHitScanParams Params;
				Params.TargetPlayer = Player;
				Params.Distance = Math::Saturate(ProjectedPassbyLocation.Distance(Player.ActorLocation) / 1000);
				Params.NormalizedDirection = NormalizedDirectionValue;

				UHitscanProjectileEffectEventHandler::Trigger_HitscanProjectilePassby(Cast<AHazeActor>(WalkerComp.Owner), Params);
			}
		}

	}

}