event void FSkylineBallBossSoulGrabbed();
event void FSkylineBallBossSoulThrown();
event void FSkylineBallBossSoulHit();

class ASkylineBallBossSoul : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeCombatTargetComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeCombatResponseComponent;

	UPROPERTY()
	FTimeDilationEffect TimeDilation;


	UPROPERTY(EditAnywhere)
	FHazePointOfInterestFocusTargetInfo PointOfInterestFocusTargetInfo;

	UPROPERTY()
	FApplyPointOfInterestSettings ApplyPointOfInterestSettings;

	UPROPERTY(EditInstanceOnly)
	AHazeActor TargetActor;



	UPROPERTY()
	FVector SoulFlyVelocity;
	bool bHit = false;

	UPROPERTY()
	UNiagaraSystem BlinkAwaySystem;

	UPROPERTY()
	FSkylineBallBossSoulThrown OnSoulThrown;

	UPROPERTY()
	FSkylineBallBossSoulHit OnSoulHit;

	UPROPERTY()
	FSkylineBallBossSoulGrabbed OnSoulGrabbed;


	FHazeAcceleratedVector AcceleratedLocation;

	FVector TargetLocation;

	FVector StartLocation;

	bool bGrabbable = false;

	ASkylineBallBoss BallBoss;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipTargetComponent.Disable(this);
		GravityBladeCombatTargetComponent.Disable(this);
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"HandleThrown");
		GravityBladeCombatResponseComponent.OnHit.AddUFunction(this, n"HandleHit");
		GravityBladeCombatResponseComponent.AddResponseComponentDisable(this, true);

		TListedActors<ASkylineBallBoss> BallBossActors;
		if (BallBossActors.Num() > 0)
		{
			BallBoss = BallBossActors[0];
			BallBoss.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");
			if (BallBoss.GetPhase() >=  ESkylineBallBossPhase::TopDeath)
				GravityBladeCombatResponseComponent.RemoveResponseComponentDisable(this, true);
		}
	}

	UFUNCTION()
	private void HandlePhaseChanged(ESkylineBallBossPhase NewPhase)
	{
		if (NewPhase == ESkylineBallBossPhase::TopMioOnEyeBroken)
			SetActorHiddenInGame(true);

		if (NewPhase == ESkylineBallBossPhase::TopMioIn)
		{
			Timer::SetTimer(this, n"UnHideEye", 1.0);
		}

		if (NewPhase == ESkylineBallBossPhase::TopDeath)
		{
			GravityBladeCombatResponseComponent.RemoveResponseComponentDisable(this, true);
		}
	}

	UFUNCTION()
	private void UnHideEye()
	{
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent,
	                          UGravityWhipTargetComponent TargetComponent, FHitResult HitResult,
	                          FVector Impulse)
	{
		TargetLocation = TargetActor.ActorLocation + FVector(0.0, 300.0, 150.0);

		OnSoulThrown.Broadcast();
		GravityBladeCombatTargetComponent.Enable(this);
		AcceleratedLocation.SnapTo(ActorLocation);

		Timer::SetTimer(this, n"LaunchMio", 1.0);
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		TimeDilation::StopWorldTimeDilationEffect(this);
		bHit = true;
		OnSoulHit.Broadcast();
		Timer::SetTimer(this, n"BlinkAway", 4.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bGrabbable && !bHit)
		{
			AcceleratedLocation.AccelerateTo(TargetLocation, 2.0, DeltaSeconds);
			SetActorLocation(AcceleratedLocation.Value);
		}

		if (bHit)
		{
			AddActorWorldOffset(SoulFlyVelocity * DeltaSeconds);
		}
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		//TargetLocation = StartLocation;
		TargetLocation = Game::Mio.ActorLocation + Game::Mio.ViewRotation.ForwardVector * 300.0;

		OnSoulThrown.Broadcast();

		Timer::SetTimer(this, n"LaunchMio", 1.0);
	}

	UFUNCTION()
	private void LaunchMio()
	{
		FVector LaunchMioForce = (StartLocation + FVector::UpVector * 200.0 - Game::Mio.ActorLocation).GetSafeNormal();
		//Game::Mio.AddMovementImpulse(FVector(LaunchMioForce * 2000.0));
		TimeDilation::StartWorldTimeDilationEffect(TimeDilation, this);
		GravityBladeCombatTargetComponent.Enable(this);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
	                           TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		TargetLocation = Game::Zoe.ViewLocation + Game::Zoe.ViewRotation.ForwardVector * 500.0;
		OnSoulGrabbed.Broadcast();
	}

	UFUNCTION()
	void EnableGrabbing()
	{
		DetachFromActor(EDetachmentRule::KeepWorld);
		GravityWhipTargetComponent.Enable(this);
		bGrabbable = true;

		//Game::Mio.ApplyPointOfInterest(this, PointOfInterestFocusTargetInfo, ApplyPointOfInterestSettings);

		StartLocation = ActorLocation;
		AcceleratedLocation.SnapTo(StartLocation);
		TargetLocation = StartLocation;
	}

	UFUNCTION()
	private void BlinkAway()
	{
		BP_BlinkAway();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_BlinkAway()
	{}
};