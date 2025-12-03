UCLASS(Abstract)
class AIslandPhasablePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent DefaultSceneRoot;

	UPROPERTY(DefaultComponent, Attach = DefaultSceneRoot)
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	UStaticMeshComponent Cone;
	default Cone.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	USceneComponent ParticleLocation;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditDefaultsOnly)
	float PullRadius = 300.0;

	UPROPERTY(EditAnywhere)
	bool bDisableBobbing = false;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem RedParticleEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BlueParticleEffect;

	UMaterialInstanceDynamic PhaseMaterial;
	bool bParticlesCurrentlyPhasing = false;

	UPROPERTY(EditAnywhere)
	bool bBlue = true;

	UPROPERTY(EditAnywhere)
	bool bBoostWall = false;

	UPROPERTY(EditAnywhere)
	bool bAttached = false;
	
	UPROPERTY(EditAnywhere)
	bool bNoAttachments = false;

	float AmbientMovementStartTime = 0;
	
	UPROPERTY(EditInstanceOnly)
	float AmbientMovementAmplitude = 15;

	UPROPERTY(EditInstanceOnly)
	float AmbientMovementDuration = 5;

	UPROPERTY(EditInstanceOnly)
	AIslandPhasablePlatformSpline PlatformSpline;

	UPROPERTY(EditAnywhere)
	bool bAlwaysLaunchForward = false;

	UPROPERTY(VisibleAnywhere)
	bool bIsLastSplinePhasable = false;

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Tools")
	void RunConstructionScriptForAll() 
	{
		TListedActors<AIslandPhasablePlatform> ListedPhasablePlatforms;
		for(AIslandPhasablePlatform Platform : ListedPhasablePlatforms.Array)
		{
			Platform.RerunConstructionScripts();
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PhaseMaterial = Cone.CreateDynamicMaterialInstance(0);
		PhaseMaterial.SetScalarParameterValue(n"PullRadius", PullRadius);
		Cone.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");

		if(bAttached)
			AmbientMovementStartTime = 0;
		else
			AmbientMovementStartTime = Math::RandRange(0.0, AmbientMovementDuration);
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(CanPhaseThrough(Player))
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(IsBlue() ? BlueParticleEffect : RedParticleEffect, Player.ActorCenterLocation, WorldScale = FVector(0.1));
			Player.PlayForceFeedback(ForceFeedback, false, false, this);
			
			FPhasableWallEventData Params; //Johannes added for VO
			Params.Player = Player; //Johannes added for VO
			UIslandPhasablePlatformEffectHandler::Trigger_OnPlayerPhaseThrough(this, Params);
		}
		else
		{
			Player.KillPlayer();
			if(ShouldGameOver())
				Player.OtherPlayer.KillPlayer();

			FPhasableWallEventData Params; //Johannes added for VO
			Params.Player = Player; //Johannes added for VO

			UIslandPhasablePlatformEffectHandler::Trigger_OnPlayerKilled(this, Params);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ClosestPlayerDistance = Game::GetDistanceFromLocationToClosestPlayer(ActorLocation);

		if (ClosestPlayerDistance < 5000.0 || bParticlesCurrentlyPhasing)
		{
			float Dist = GetPlayerToPhasablePlatformDistance();
			if(Dist < PullRadius && !bParticlesCurrentlyPhasing)
			{
				bParticlesCurrentlyPhasing = true;
				UIslandPhasablePlatformEffectHandler::Trigger_OnParticlesBeginPhasing(this);
			}
			else if(Dist > PullRadius && bParticlesCurrentlyPhasing)
			{
				bParticlesCurrentlyPhasing = false;
				UIslandPhasablePlatformEffectHandler::Trigger_OnParticlesStopPhasing(this);
			}
		}

		if (ClosestPlayerDistance < 5000.0)
		{
			FBox Box = Cone.GetComponentLocalBoundingBox();
			FHazeShapeSettings BoxSettings = FHazeShapeSettings::MakeBox(Box.Extent);
			ParticleLocation.WorldLocation = BoxSettings.GetClosestPointToPoint(Cone.WorldTransform, PhasablePlayer.ActorLocation);
		}

		if (bDisableBobbing)
			return;

		if (ClosestPlayerDistance < 10000.0)
		{
			float Time = Math::Wrap(Time::PredictedGlobalCrumbTrailTime - AmbientMovementStartTime, 0, AmbientMovementDuration);
			float SinMove = Math::Sin(Time/AmbientMovementDuration*PI*2)*AmbientMovementAmplitude * 1.5;
			MovingRoot.SetRelativeLocation(FVector(MovingRoot.RelativeLocation.X,MovingRoot.RelativeLocation.Y,SinMove));
		}
	}

	// Implement in Blueprint because this is a property that was defined in bp so instead of breaking all instance modifications we do this instead.
	UFUNCTION(BlueprintEvent)
	bool IsBlue() const
	{
		return false;
	}

	// Implement in Blueprint because this is a property that was defined in bp so instead of breaking all instance modifications we do this instead.
	UFUNCTION(BlueprintEvent)
	bool ShouldGameOver() const
	{
		return false;
	}

	bool CanPhaseThrough(AHazePlayerCharacter Player) const
	{
		return IsBlue() == Player.IsZoe();
	}

	float GetPlayerToPhasablePlatformDistance() const
	{
		FBox Box = Cone.GetComponentLocalBoundingBox();
		FHazeShapeSettings BoxSettings = FHazeShapeSettings::MakeBox(Box.Extent);
		return BoxSettings.GetWorldDistanceToShape(Cone.WorldTransform, PhasablePlayer.ActorLocation);
	}

	/* Will return a value between 0 and 1. 1 is just at the phasable platform and 0 is when the player is PullRadius distance away or further. */
	UFUNCTION(BlueprintPure)
	float Audio_GetPlayerToPhasablePlatformAlpha() const
	{
		float Dist = GetPlayerToPhasablePlatformDistance();
		float Alpha = Math::Saturate(Dist / PullRadius);
		return 1.0 - Alpha;
	}

	AHazePlayerCharacter GetPhasablePlayer() const property
	{
		if(IsBlue())
			return Game::Zoe;

		return Game::Mio;
	}
}