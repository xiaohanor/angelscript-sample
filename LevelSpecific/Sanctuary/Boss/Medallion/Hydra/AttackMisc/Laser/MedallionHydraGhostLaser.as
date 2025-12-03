enum EMedallionHydraLaserType
{
	None,
	SidescrollerAbove,
	SidescrollerDownwardsSweep,
	FlyingDownwardsSweep,
	BallistaUpwardsSweep
}

class AMedallionHydraGhostLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent WaterSplashComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BreathMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BreathVFX;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditInstanceOnly)
	AHazeActor WaterPlaneActor;
	ASanctuaryBossMedallionHydra OwningHydra;
	
	EMedallionHydraLaserType LaserType = EMedallionHydraLaserType::None;
	UFUNCTION(BlueprintPure)
	EMedallionHydraLaserType GetLaserType() const { return LaserType; };	

	const float DefaultTelegraphDuration = 1.0;
	const float ActivateLaserDuration = 0.3;
	const float DeactivateLaserDuration = 0.5;
	const float GodrayMaxOpacity = 1.0;
	const float LaserRadius = 350.0;
	const float DamageRate = 1.0;
	const float FFRadius = 1000.0;
	const float LaserLength = 30000.0;

	TPerPlayer<float> LastDamageTime;
	bool bActive = false;
	bool bLasering = false;

	bool bShouldKnockback = false;

	private UHazeAudioEmitter GhostLaserAudioEmitter;

	UFUNCTION(BlueprintPure)	
	UHazeAudioEmitter GetGhostLaserAudioEmitter() const { return GhostLaserAudioEmitter; }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAudioEmitter();
	}

	private void GetAudioEmitter()
	{
		FHazeAudioEmitterAttachmentParams EmitterParams;
		EmitterParams.Attachment = RootComponent;
		
		#if TEST
		EmitterParams.EmitterName = n"GhostLaserEmitter";
		#endif

		EmitterParams.Instigator = this;
		EmitterParams.Owner = this;
		EmitterParams.bCanAttach = true;

		GhostLaserAudioEmitter = Audio::GetPooledEmitter(EmitterParams);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActive)
			return;
		
		SetActorRotation(OwningHydra.HeadPivot.WorldRotation);

		if (!bLasering)
			return;

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.UseSphereShape(LaserRadius);
	
		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + ActorForwardVector * LaserLength);
		auto HitPlatform = Cast<ASanctuaryBossArenaFloatingPlatform>(HitResult.Actor);

		if (HitPlatform != nullptr)
		{
			float ForceSidewaysMultiplier = HitResult.ImpactPoint.Dist2D(HitResult.Location, FVector::UpVector) / LaserRadius;
			FVector LaserForce = FVector::UpVector * -10000.0  * ForceSidewaysMultiplier;
			FauxPhysics::ApplyFauxForceToActorAt(HitPlatform, HitResult.ImpactPoint, LaserForce);
		}


		for (auto Player : Game::Players)
		{
			FVector ClosestLaserLocation = Math::ClosestPointOnLine(
				ActorLocation, 
				ActorLocation + ActorForwardVector * 100000.0,
				Player.ActorLocation);

			float DistanceToPlayer = ClosestLaserLocation.Distance(Player.ActorLocation);

			if (DistanceToPlayer < LaserRadius && LastDamageTime[Player] + DamageRate < Time::GameTimeSeconds)
				DamagePlayer(Player);
			
			float Alpha = Math::Saturate(DistanceToPlayer / FFRadius);
			float FFStrength = Math::Lerp(1.0, 0.0, Alpha);

			if (FFStrength > 0.0)
				Player.SetFrameForceFeedback(FFStrength, FFStrength, FFStrength, FFStrength);
		}

		FPlane WaterPlane = FPlane(WaterPlaneActor.ActorLocation, FVector::UpVector);
		FVector ImpactLocation;
		float32 Time;

		bool bIntersectingWater = Math::LinePlaneIntersection(
			ActorLocation,
			ActorLocation + ActorForwardVector * LaserLength,
			WaterPlane,
			Time,
			ImpactLocation
		);

		WaterSplashComp.SetWorldLocation(ImpactLocation);

		if (WaterSplashComp.IsActive() && !bIntersectingWater)
			WaterSplashComp.Deactivate();

		if (!WaterSplashComp.IsActive() && bIntersectingWater)
		{
			FSanctuaryBossMedallionHydraGhostLaserData Params;
			Params.Hydra = OwningHydra;
			Params.GhostLaser = this;
			Params.PlayerTarget = Game::GetClosestPlayer(OwningHydra.ActorLocation);	

			UMedallionHydraAttackManagerEventHandler::Trigger_OnLaserImpactWater(OwningHydra.Refs.HydraAttackManager, Params);
			WaterSplashComp.Activate(true);
		}

		if (!bIntersectingWater)
			ImpactLocation = ActorLocation + ActorForwardVector * LaserLength;

		BP_ActiveTick(ImpactLocation, bIntersectingWater);
	}

	void DamagePlayer(AHazePlayerCharacter Player)
	{
		LastDamageTime[Player] = Time::GameTimeSeconds;
		Player.DamagePlayerHealth(0.5);

		if (bShouldKnockback)
		{
			FVector KnockbackMove = FRotator::MakeFromZX(FVector::UpVector, ActorForwardVector).ForwardVector * 500.0 +
									FVector::UpVector * 500.0;

			Player.ApplyKnockdown(KnockbackMove, 2.0);
		}
	}

	void ActivateLaser(float TelegraphDuration = -1.0, bool bKnockback = false, EMedallionHydraLaserType NewLaserType = EMedallionHydraLaserType::None)
	{
		float ActualTelegraphDuration;
		if (TelegraphDuration < 0.0)
			ActualTelegraphDuration = DefaultTelegraphDuration;
		else
			ActualTelegraphDuration = TelegraphDuration;

		bShouldKnockback = bKnockback;

		bActive = true;

		BP_StartTelegraph();
		if(NewLaserType != EMedallionHydraLaserType::None)
			LaserType = NewLaserType;

		QueueComp.Idle(ActualTelegraphDuration);
		QueueComp.Event(this, n"ActivateLaserVFX");

		FSanctuaryBossMedallionHydraGhostLaserData Params;
		Params.Hydra = OwningHydra;
		Params.PlayerTarget = Game::GetClosestPlayer(OwningHydra.ActorLocation);
		Params.GhostLaser = this;	
		Params.TelegraphDuration = ActualTelegraphDuration;

		OwningHydra.FaceComp.RequestEmissiveFace(this, SanctuaryBossMedallionHydraEmissiveFaceCurve_GhostLaser);

		UMedallionHydraAttackManagerEventHandler::Trigger_OnTelegraphLaser(OwningHydra.Refs.HydraAttackManager, Params);
	}

	void DeactivateLaser()
	{	
		if (bActive)
		{
			QueueComp.Empty();
			QueueComp.Event(this, n"DeactivateLaserVFX");
			BP_StopTelegraph();

			OwningHydra.FaceComp.RemoveEmissiveFaceByInstigator(this);

			FSanctuaryBossMedallionHydraGhostLaserData Params;
			Params.Hydra = OwningHydra;
			Params.GhostLaser = this;
			Params.PlayerTarget = Game::GetClosestPlayer(OwningHydra.ActorLocation);	

			UMedallionHydraAttackManagerEventHandler::Trigger_OnLaserStop(OwningHydra.Refs.HydraAttackManager, Params);
		}
		else if (!QueueComp.IsEmpty())
		{
			QueueComp.Empty();
			BP_StopTelegraph();
		}
	}

	UFUNCTION()
	private void ActivateLaserVFX()
	{
		BreathVFX.Activate(true);
		BreathMeshComp.SetHiddenInGame(false);
		bLasering = true;

		FSanctuaryBossMedallionHydraGhostLaserData Params;
		Params.Hydra = OwningHydra;
		Params.PlayerTarget = Game::GetClosestPlayer(OwningHydra.ActorLocation);
		Params.GhostLaser = this;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnLaserStart(OwningHydra.Refs.HydraAttackManager, Params);

		BP_StopTelegraph();
		BP_Activate();
	}

	UFUNCTION()
	private void DeactivateLaserVFX()
	{
		WaterSplashComp.Deactivate();
		BreathVFX.Deactivate();
		BreathMeshComp.SetHiddenInGame(true);
		bActive = false;
		bLasering = false;

		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_StartTelegraph(){}

	UFUNCTION(BlueprintEvent)
	private void BP_StopTelegraph(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivate(){}

	UFUNCTION(BlueprintEvent)
	private void BP_ActiveTick(FVector ImpactLocation, bool bHittingWater){}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Audio::ReturnPooledEmitter(this, GhostLaserAudioEmitter);
	}
};