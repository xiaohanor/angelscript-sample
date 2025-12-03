event void FOilRigDodgeProjectileEvent(AHazePlayerCharacter Player);

class AOilRigDodgeProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent, Attach = ProjectileRoot)
	UCapsuleComponent PlayerTrigger;

	UPROPERTY(DefaultComponent, Attach = ProjectileRoot)
	USceneComponent DangerZoneRoot;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocation;
	default SyncedLocation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY()
	FOilRigDodgeProjectileEvent OnDodged;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LandFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ExplodeCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ExplodeFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bLaunched = false;
	bool bInAir = false;
	bool bLanded = false;
	bool bExploded = false;

	AHazePlayerCharacter TargetPlayer;

	float ExplodeDelay = 0.7;
	FTimerHandle ExplodeTimerHandle;

	bool bDurationExtended = false;
	float ExtendTime = 0.4;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");
	}

	UFUNCTION()
	private void ExitTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!bLanded)
			return;

		if (bExploded)
			return;

		// Explode();
		OnDodged.Broadcast(Player);
	}

	void LaunchProjectile(AHazePlayerCharacter Player)
	{
		if (bLaunched)
			return;

		UOilRigDodgeProjectileEventHandler::Trigger_Launched(this);
		
		bLaunched = true;
		bInAir = true;
		TargetPlayer = Player;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLand()
	{
		if (bLanded)
			return;

		bInAir = false;
		bLanded = true;

		BP_Landed();

		UOilRigDodgeProjectileEventHandler::Trigger_Landed(this);

		ExplodeTimerHandle = Timer::SetTimer(this, n"Explode", ExplodeDelay);

		ForceFeedback::PlayWorldForceFeedback(LandFF, ActorLocation, true, this, 200.0, 100.0);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Landed() {}

	UFUNCTION()
	private void Explode()
	{
		if (HasControl())
			CrumbExplode();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExplode()
	{
		if (bExploded)
			return;
		
		bExploded = true;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (PlayerTrigger.IsOverlappingActor(Player))
				Player.KillPlayer(FPlayerDeathDamageParams((Player.ActorCenterLocation - ActorLocation).GetSafeNormal()), DeathEffect);
		}

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ExplodeCamShake, this, ActorLocation, 600.0, 1000.0);

		ForceFeedback::PlayWorldForceFeedback(ExplodeFF, ActorLocation, true, this, 600.0, 400.0);

		UOilRigDodgeProjectileEventHandler::Trigger_Exploded(this);

		BP_Explode();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HasControl())
		{
			if (bInAir)
			{
				FVector TargetLoc = TargetPlayer.ActorLocation;
				
				FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				TraceSettings.IgnorePlayers();
				TraceSettings.IgnoreActor(this);
				TraceSettings.UseLine();

				FHitResult Hit = TraceSettings.QueryTraceSingle(TargetPlayer.ActorCenterLocation, TargetPlayer.ActorCenterLocation - (FVector::UpVector * 1000.0));
				TargetLoc.Z = Hit.Location.Z;

				FVector Loc = Math::VInterpConstantTo(ActorLocation, TargetLoc, DeltaTime, 3000.0);
				SetActorLocation(Loc);

				SyncedLocation.Value = Loc;

				if (Loc.Equals(TargetLoc))
					CrumbLand();
			}
		}
		else
		{
			SetActorLocation(SyncedLocation.Value);
		}
	}

	void ExtendDuration()
	{
		if (bDurationExtended)
			return;

		bDurationExtended = true;
		ExplodeTimerHandle = Timer::SetTimer(this, n"Explode", ExplodeTimerHandle.RemainingTime + ExtendTime);
	}
}

class UOilRigDodgeProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Landed() {}

	UFUNCTION(BlueprintEvent)
	void Exploded() {}

	UFUNCTION(BlueprintEvent)
	void Launched() {}

}