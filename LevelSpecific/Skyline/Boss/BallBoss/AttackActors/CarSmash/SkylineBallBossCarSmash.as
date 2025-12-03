class ASkylineBallBossCarSmash : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;


	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SmashRoot;

	UPROPERTY(DefaultComponent, Attach = SmashRoot)
	USceneComponent Car1Root;
	UPROPERTY(DefaultComponent, Attach = Car1Root)
	USceneComponent Car1BaseRoot;
	UPROPERTY(DefaultComponent, Attach = Car1Root)
	USceneComponent Car1BrokenRoot;
	UPROPERTY(DefaultComponent, Attach = Car1Root)
	USkylineBallBossTractorBeamComponent TractorBeamVFXComp1;
	UPROPERTY(DefaultComponent, Attach = Car1BaseRoot)
	UStaticMeshComponent Car1Mesh;
	UPROPERTY(DefaultComponent, Attach = Car1BaseRoot)
	USpotLightComponent Car1HeadLight1;
	UPROPERTY(DefaultComponent, Attach = Car1BaseRoot)
	USpotLightComponent Car1HeadLight2;

	UPROPERTY(DefaultComponent, Attach = SmashRoot)
	USceneComponent Car2Root;
	UPROPERTY(DefaultComponent, Attach = Car2Root)
	USceneComponent Car2BaseRoot;
	UPROPERTY(DefaultComponent, Attach = Car2Root)
	USceneComponent Car2BrokenRoot;
	UPROPERTY(DefaultComponent, Attach = Car2Root)
	USkylineBallBossTractorBeamComponent TractorBeamVFXComp2;
	UPROPERTY(DefaultComponent, Attach = Car2BaseRoot)
	UStaticMeshComponent Car2Mesh;
	UPROPERTY(DefaultComponent, Attach = Car2BaseRoot)
	USpotLightComponent Car2HeadLight1;
	UPROPERTY(DefaultComponent, Attach = Car2BaseRoot)
	USpotLightComponent Car2HeadLight2;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;



	UPROPERTY()
	FHazeTimeLike SmashTimeLike;
	default SmashTimeLike.UseSmoothCurveZeroToOne();
	default SmashTimeLike.Duration = 0.5;

	UPROPERTY()
	FRuntimeFloatCurve SmashCurve;

	UPROPERTY()
	float CarToCenterDistance = 1200.0;

	UPROPERTY()
	float TargetDuration = 4.0;

	UPROPERTY()
	float DamageRadius = 600.0;

	UPROPERTY()
	UNiagaraSystem ExplosionVFXSystem;

	private AHazePlayerCharacter TargetedPlayer;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor CameraActor;

	FHazeAcceleratedVector AcceleratedSmashLocation;
	ASkylineBallBoss BallBoss = nullptr;

	bool bTargetingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SmashTimeLike.BindUpdate(this, n"SmashUpdate");
		SmashTimeLike.BindFinished(this, n"SmashFinished");

		Car1BrokenRoot.SetHiddenInGame(true, true);
		Car2BrokenRoot.SetHiddenInGame(true, true);

		AddActorDisable(this);

		TractorBeamVFXComp1.SetupTractorBeamMaterial(Car1Mesh);
		TractorBeamVFXComp2.SetupTractorBeamMaterial(Car2Mesh);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bTargetingPlayer)
		{
			TryCacheBallBoss();
			TargetedPlayer = BallBoss.FocusPlayerComponent.GetViableFocusPlayer(TargetedPlayer);
			AcceleratedSmashLocation.AccelerateTo(FVector(ActorLocation.X, TargetedPlayer.ActorLocation.Y, ActorLocation.Z + 1700.0), 2.0, DeltaSeconds);
		}
		
		SmashRoot.SetWorldLocation(AcceleratedSmashLocation.Value);
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorDisable(this);
		TryCacheBallBoss();
		TractorBeamVFXComp1.Start();
		TractorBeamVFXComp2.Start();

		TargetedPlayer = BallBoss.FocusPlayerComponent.GetFlipFlopFocusPlayer();
		bTargetingPlayer = true;
		AcceleratedSmashLocation.SnapTo(ActorLocation);
		Car1Root.SetRelativeLocation(FVector::RightVector * CarToCenterDistance);
		Car2Root.SetRelativeLocation(FVector::LeftVector * CarToCenterDistance);
		USkylineBallBossCarSmashEventHandler::Trigger_AppearStart(this);

		QueueComp.Idle(TargetDuration);
		QueueComp.Event(this, n"StartSmash");
		QueueComp.Duration(2.0, this, n"SmashUpdate");
		QueueComp.Event(this, n"SmashFinished");
		QueueComp.Idle(0.5);
		QueueComp.Duration(0.3, this, n"ThrowAwayUpdate");
		QueueComp.Event(this, n"ThrowAway");
		QueueComp.Duration(1.5, this, n"FallTimeLikeUpdate");
		QueueComp.Event(this, n"FallFinished");
	}

	

	UFUNCTION()
	void StartSmash()
	{
		bTargetingPlayer = false;

		BP_StartSmash();

		USkylineBallBossMiscVOEventHandler::Trigger_SmashingCarSmash(BallBoss);
		USkylineBallBossCarSmashEventHandler::Trigger_StartSmash(this);
	}

	UFUNCTION()
	private void SmashUpdate(float Alpha)
	{
		float CurrentValue = SmashCurve.GetFloatValue(Alpha);
		
		Car1Root.SetRelativeLocation(FVector::RightVector * CarToCenterDistance * CurrentValue);
		Car2Root.SetRelativeLocation(FVector::LeftVector * CarToCenterDistance * CurrentValue);
	}

	UFUNCTION()
	private void SmashFinished()
	{
		Car1BrokenRoot.SetHiddenInGame(false, true);
		Car2BrokenRoot.SetHiddenInGame(false, true);

		Car1BaseRoot.SetHiddenInGame(true, true);
		Car2BaseRoot.SetHiddenInGame(true, true);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFXSystem, SmashRoot.WorldLocation);

		for (auto Player : Game::Players)
		{
			if (Player.ActorLocation.Distance(SmashRoot.WorldLocation) < DamageRadius)
				Player.KillPlayer(FPlayerDeathDamageParams(FVector::UpVector, 2.0), BallBoss.ObjectLargeDeathEffect);
		}

		USkylineBallBossCarSmashEventHandler::Trigger_Collide(this);
		USkylineBallBossEventHandler::Trigger_CarSmashCollide(BallBoss);
		BP_Smash();
	}

	UFUNCTION()
	private void ThrowAwayUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseIn(0.0, 1.0, Alpha, 1.0);

		Car1Root.SetRelativeLocation(FVector::RightVector * CarToCenterDistance * CurrentValue);
		Car2Root.SetRelativeLocation(FVector::LeftVector * CarToCenterDistance * CurrentValue);

		Car1BrokenRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, 15.0, CurrentValue), 0.0, 0.0));
		Car2BrokenRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, -15.0, CurrentValue), 0.0, 0.0));
	}

	UFUNCTION()
	private void ThrowAway()
	{	
		TractorBeamVFXComp1.TractorBeamLetGo();
		TractorBeamVFXComp2.TractorBeamLetGo();
		USkylineBallBossCarSmashEventHandler::Trigger_ThrowAwayCars(this);
	}

	UFUNCTION()
	private void FallTimeLikeUpdate(float Alpha)
	{
		float SidewaysAlpha = Math::EaseOut(1.0, 2.5, Alpha, 2.0);
		float CurrentValue = Math::EaseIn(0.0, 1.0, Alpha, 2.0);

		Car1Root.SetRelativeLocation(FVector::RightVector * CarToCenterDistance * SidewaysAlpha +
									FVector::UpVector * -3000.0 * CurrentValue);
		Car2Root.SetRelativeLocation(FVector::LeftVector * CarToCenterDistance * SidewaysAlpha +
									FVector::UpVector * -3000.0 * CurrentValue);

		Car1BrokenRoot.SetRelativeRotation(FRotator(Math::Lerp(15.0, 70.0, CurrentValue), 0.0, 0.0));
		Car2BrokenRoot.SetRelativeRotation(FRotator(Math::Lerp(-15.0, -70.0, CurrentValue), 0.0, 0.0));
	}

	UFUNCTION()
	private void FallFinished()
	{
		Car1BrokenRoot.SetHiddenInGame(true, true);
		Car2BrokenRoot.SetHiddenInGame(true, true);

		Car1BaseRoot.SetHiddenInGame(false, true);
		Car2BaseRoot.SetHiddenInGame(false, true);

		Car1BrokenRoot.SetRelativeRotation(FRotator::ZeroRotator);
		Car2BrokenRoot.SetRelativeRotation(FRotator::ZeroRotator);

		AddActorDisable(this);
	}

	
	UFUNCTION(BlueprintEvent)
	void BP_StartSmash(){}

	UFUNCTION(BlueprintEvent)
	void BP_Smash(){}
	
	private void TryCacheBallBoss()
	{
		if (BallBoss == nullptr)
		{
			TListedActors<ASkylineBallBoss> BallBosses;
			if (BallBosses.Num() == 1)
				BallBoss = BallBosses[0];
		}
	}

};

class USkylineBallBossCarSmashEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AppearStart() 
	{
		//PrintToScreen("AppearStart", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AppearEnd() 
	{
		//PrintToScreen("AppearEnd", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSmash()
	{
		//PrintToScreen("Smash", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Collide()
	{
		//PrintToScreen("Collide", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrowAwayCars()
	{
		//PrintToScreen("ThrowAwayCars", 5.0);
	}

};