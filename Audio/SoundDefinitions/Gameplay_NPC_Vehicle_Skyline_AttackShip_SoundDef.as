
UCLASS(Abstract)
class UGameplay_NPC_Vehicle_Skyline_AttackShip_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStopAimLaser(FSkylineAttackShipAttackEventData Params){}

	UFUNCTION(BlueprintEvent)
	void OnStartAimLaser(FSkylineAttackShipAttackEventData Params){}

	UFUNCTION(BlueprintEvent)
	void OnShieldDamage(FSkylineAttackShipShieldEventData Params){}

	UFUNCTION(BlueprintEvent)
	void OnWeakPointHit(){}

	UFUNCTION(BlueprintEvent)
	void OnCrash(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadWrite)
	ASkylineAttackShip AttackShip;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter TurretEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter MissilesEmitter;

	private TArray<ASkylineAttackShipProjectileBase> Projectiles;
	private TArray<FAkSoundPosition> MissileEmitterPositions;
	default MissileEmitterPositions.SetNum(2);

	private int GrabCount = 0;

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Has Active Missiles"))
	bool HasActiveMissiles()
	{
		return Projectiles.Num() > 0;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Missiles Grabbed"))
	bool IsMissilesGrabbed()
	{
		return GrabCount > 0;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AttackShip = Cast<ASkylineAttackShip>(HazeOwner);	
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;

		if(EmitterName == n"MissilesEmitter")
		{
			bUseAttach = false;
			return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(HasActiveMissiles())
		{
			// We only want the two latest positions.
			int ProjectileIndex = Projectiles.Num() - 1;
			for(int PositionIndex = 0; PositionIndex < MissileEmitterPositions.Num(); ++PositionIndex)
			{
				MissileEmitterPositions[PositionIndex].SetPosition(Projectiles[ProjectileIndex].ActorLocation);
				
				if (ProjectileIndex > 0)
					--ProjectileIndex;
			}

			MissilesEmitter.AudioComponent.SetMultipleSoundPositions(MissileEmitterPositions);
		}		
	}

	UFUNCTION(BlueprintEvent)
	void FireMissiles(AHazePlayerCharacter PlayerTarget, bool bWasFirstMissile) {}

	UFUNCTION(BlueprintEvent)
	void MissileExplode(ASkylineAttackShipProjectileBase Projectile, bool bWasLastMissile) {}

	UFUNCTION(BlueprintEvent)
	void OnMissilesGrabbed(bool bWasLastGrab) {}

	UFUNCTION(BlueprintEvent)
	void OnMissilesThrown(bool bWasLastGrab) {}

	UFUNCTION(NotBlueprintCallable)
	void OnFireMissiles(FSkylineAttackShipAttackEventData Params)
	{
		const bool bFirst = Projectiles.Num() == 0;
		Projectiles.Add(Params.Projectile);
		Params.Projectile.OnExpired.AddUFunction(this, n"OnProjectileExplode");
		Params.Projectile.GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnProjectileGrabbed");		

		FireMissiles(Params.TargetPlayer, bFirst);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnProjectileExplode(ASkylineAttackShipProjectileBase Projectile)
	{
		bool bLast = false;
		if(HasActiveMissiles())
		{
			bLast = Projectiles.Num() == 1;
			Projectiles.RemoveSingleSwap(Projectile);
		}

		Projectile.OnExpired.UnbindObject(this);
		Projectile.GravityWhipResponseComponent.OnGrabbed.UnbindObject(this);
		Projectile.GravityWhipResponseComponent.OnThrown.UnbindObject(this);
		MissilesEmitter.AudioComponent.DetachFromParent();

		MissileExplode(Projectile, bLast);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnProjectileGrabbed(UGravityWhipUserComponent UserComp, UGravityWhipTargetComponent TargetComp, TArray<UGravityWhipTargetComponent> OtherTargets)
	{
		ASkylineAttackShipProjectileBase Projectile = Cast<ASkylineAttackShipProjectileBase>(TargetComp.Owner);
		Projectiles.RemoveSingleSwap(Projectile);
		Projectile.GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"OnProjectileThrown");
		const bool bLast = !HasActiveMissiles();

		OnMissilesGrabbed(bLast);
		
		TArray<FAkSoundPosition> Empty;
		MissilesEmitter.AudioComponent.SetMultipleSoundPositions(Empty);
		MissilesEmitter.AudioComponent.SetWorldLocation(Projectile.RootComponent.WorldLocation);
		MissilesEmitter.AudioComponent.AttachTo(Projectile.RootComponent, AttachType = EAttachLocation::SnapToTarget);

		++GrabCount;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnProjectileThrown(UGravityWhipUserComponent UserComp, UGravityWhipTargetComponent TargetComp, FHitResult HitResult, FVector Impulse)
	{
		--GrabCount;
		const bool bLast = (GrabCount == 0);
		OnMissilesThrown(bLast);
	}	

	UFUNCTION(BlueprintPure)
	bool IsOnCrashSpline()
	{
		return AttackShip.Spline == AttackShip.CrashSpline;
	}
}