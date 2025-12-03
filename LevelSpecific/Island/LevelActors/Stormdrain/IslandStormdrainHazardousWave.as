struct FHazardousWavePlatformImpactParams
{
	UPROPERTY()
	FVector PlatformLocation;
}

class AIslandStormdrainHazardousWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 75000.0;

	UPROPERTY(DefaultComponent)
	UBoxComponent OverlapBox;
	default OverlapBox.CollisionEnabled = ECollisionEnabled::NoCollision;
	default OverlapBox.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = OverlapBox)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandStormdrainHazardousWaveDummyComponent DummyComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Movement")
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Movement")
	float MovementDuration = 5.0;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float MovementWaitTime = 5.0;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float MoveMax = 50000.0;

	UPROPERTY(EditAnywhere, Category = "Platforms")
	float PlatformImpulseSize = 500.0;

	UPROPERTY(EditAnywhere, Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> CameraShakePassingOverPlayers;
	
	UPROPERTY(EditAnywhere, Category = "Camera Shake")
	UForceFeedbackEffect FFPassingOverPlayers;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	FVector StartLocation;
	float StartTime;
	float StoppedTime;

	bool bIsMoving = false;
	bool bQueuedStartMovement = false;
	bool bQueuedStopMovement = false;

	UPROPERTY(BlueprintReadOnly)
	bool bWaveActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		ToggleWave(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bWaveActive)
			return;

		if(bIsMoving)
		{
			ActorLocation = GetMovementLocation(StartLocation);
			UpdateWaveOverlaps();
			if(HasReachedEndOfMovement())
			{
				StopMovement();
			}
		}
		else
		{
			if(ShouldStartMovement())
			{
				ActorLocation = StartLocation;
				StartMovement();
			}
		}
	}

	FVector GetMovementLocation(FVector InStartLocation)
	{
		float Alpha = GetMovementAlpha();

		float MovedFraction = MoveCurve.GetFloatValue(Alpha);
		FVector MoveDelta = ActorForwardVector * MoveMax * MovedFraction;
		return InStartLocation + MoveDelta;
	}

	UFUNCTION(BlueprintPure)
	float GetMovementAlpha() const
	{
		float TimeSinceStart = Time::GetGameTimeSince(StartTime);
		return Math::Saturate(TimeSinceStart / MovementDuration);
	}

	UFUNCTION()
	void ShutdownWave()
	{
		bWaveActive = false;
		StopMovement(false);
		UIslandStormdrainHazardousWaveEffectHandler::Trigger_OnShutDown(this);
	}

	UFUNCTION()
	void StartWave()
	{
		bWaveActive = true;
	}

	void StartMovement()
	{
		if(Network::IsGameNetworked())
		{
			if(!HasControl())
				return;

			if(bQueuedStartMovement)
				return;

			Timer::SetTimer(this, n"LocalStartMovement", Network::PingOneWaySeconds);
			NetRemoteStartMovement();
			bQueuedStartMovement = true;
		}
		else
		{
			LocalStartMovement();
		}
	}

	UFUNCTION(NetFunction)
	private void NetRemoteStartMovement()
	{
		if(HasControl())
			return;

		LocalStartMovement();
	}

	UFUNCTION()
	private void LocalStartMovement()
	{
		ToggleWave(true);
		StartTime = Time::GetGameTimeSeconds();
		bIsMoving = true;
		bQueuedStartMovement = false;
		UIslandStormdrainHazardousWaveEffectHandler::Trigger_OnWaveStartMoving(this);
	}

	void StopMovement(bool bReachEnd = true)
	{
		if(Network::IsGameNetworked())
		{
			if(!HasControl())
				return;

			if(bQueuedStopMovement)
				return;

			if(bReachEnd)
				Timer::SetTimer(this, n"LocalStopMovementReachEnd", Network::PingOneWaySeconds);
			else
				Timer::SetTimer(this, n"LocalStopMovementNonReachEnd", Network::PingOneWaySeconds);

			NetRemoteStopMovement(bReachEnd);
			bQueuedStopMovement = true;
		}
		else
		{
			LocalStopMovement(bReachEnd);
		}
	}

	UFUNCTION(NetFunction)
	private void NetRemoteStopMovement(bool bReachEnd)
	{
		if(HasControl())
			return;

		LocalStopMovement(bReachEnd);
	}

	UFUNCTION()
	private void LocalStopMovementReachEnd()
	{
		LocalStopMovement(true);
	}

	UFUNCTION()
	private void LocalStopMovementNonReachEnd()
	{
		LocalStopMovement(false);
	}

	private void LocalStopMovement(bool bReachEnd)
	{
		ToggleWave(false);
		StoppedTime = Time::GetGameTimeSeconds();
		bIsMoving = false;
		bQueuedStopMovement = false;

		if(bReachEnd)
			UIslandStormdrainHazardousWaveEffectHandler::Trigger_OnWaveReachEnd(this);
	}

	void ToggleWave(bool bEnable)
	{
		if(bEnable)
		{
			RemoveActorCollisionBlock(this);
			RemoveActorVisualsBlock(this);
		}
		else
		{
			AddActorCollisionBlock(this);
			AddActorVisualsBlock(this);
		}
	}

	bool HasReachedEndOfMovement() const
	{
		return Time::GetGameTimeSince(StartTime) >= MovementDuration;
	}

	bool ShouldStartMovement() const
	{
		return Time::GetGameTimeSince(StoppedTime) >= MovementWaitTime;
	}

	void UpdateWaveOverlaps()
	{
		TListedActors<AIslandStormdrainFloatingShieldedPlatform> PlatformsInLevel;

		FCollisionShape BoxShape = FCollisionShape::MakeBox(OverlapBox.BoxExtent);
		FTransform BoxTransform = OverlapBox.WorldTransform;

		for(AIslandStormdrainFloatingShieldedPlatform Platform : PlatformsInLevel)
		{
			bool bOverlap = Overlap::QueryShapeOverlap(
				BoxShape, BoxTransform,
				FCollisionShape::MakeBox(Platform.PlayerEnterTrigger.Shape.BoxExtents),
				Platform.PlayerEnterTrigger.WorldTransform
			);

			if (!Platform.bIsOverlappingHazardousWave && bOverlap)
			{
				Platform.bIsOverlappingHazardousWave = true;
				if(Platform.bMendShieldsWhenSwapping)
					Platform.MendShields();
				Platform.ToggleShieldColors();

				FHazardousWavePlatformImpactParams ImpactParams;
				ImpactParams.PlatformLocation = Platform.ActorLocation;

				UIslandStormdrainHazardousWaveEffectHandler::Trigger_OnWaveImpactPlatform(this, ImpactParams);
				FauxPhysics::ApplyFauxImpulseToActorAt(Platform, Platform.ActorLocation + Platform.ActorUpVector * 10000, ActorForwardVector * PlatformImpulseSize);
			}
			else if (Platform.bIsOverlappingHazardousWave && !bOverlap)
			{
				Platform.bIsOverlappingHazardousWave = false;
			}
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			if (Overlap::QueryShapeOverlap(
				BoxShape, BoxTransform,
				Player.CapsuleComponent.GetCollisionShape(), Player.CapsuleComponent.WorldTransform
			))
			{
				bool bPlayerIsSafe = false;
				for(auto PlatformInLevel : PlatformsInLevel)
				{
					if(PlatformInLevel.IsInsideShields[Player])
					{
						bPlayerIsSafe = true;
						break;
					}
				}

				if(!bPlayerIsSafe)
					Player.KillPlayer(DeathEffect = DeathEffect);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void WaveStarted(){};
};

#if EDITOR
class UIslandStormdrainHazardousWaveDummyComponent : UActorComponent {}
class UIslandStormdrainHazardousWaveComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandStormdrainHazardousWaveDummyComponent;

	FVector SimulatedLocation;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto VisualizedComponent = Cast<UIslandStormdrainHazardousWaveDummyComponent>(Component);
		if(VisualizedComponent == nullptr)
			return;

		auto Wave = Cast<AIslandStormdrainHazardousWave>(Component.Owner);
		if(Wave == nullptr)
			return;

		DrawArrow(Wave.ActorLocation, Wave.ActorLocation + Wave.ActorForwardVector * Wave.MoveMax, FLinearColor::Red, 150, 50, false);
		
		if(Wave.bIsMoving)
		{
			SimulatedLocation = Wave.GetMovementLocation(Wave.ActorLocation);
			if(Wave.HasReachedEndOfMovement())
			{
				Wave.StopMovement();
			}
		}
		else
		{
			if(Wave.ShouldStartMovement())
			{
				SimulatedLocation = Wave.ActorLocation;
				Wave.StartMovement();
			}
		}
		
		if(Wave.bIsMoving)
		{
			DrawSolidBox(this, SimulatedLocation, Wave.OverlapBox.ComponentQuat, Wave.OverlapBox.BoundingBoxExtents, FLinearColor::Purple, 0.5, 20.0);
		}
		else
		{
			float AlphaToNextWave = Time::GetGameTimeSince(Wave.StoppedTime) / Wave.MovementWaitTime; 
			DrawSolidBox(this, Wave.ActorLocation, Wave.OverlapBox.ComponentQuat, Wave.OverlapBox.BoxExtent * AlphaToNextWave, FLinearColor::Purple, 0.5, 20.0);
		}
	}
}
#endif

UCLASS(Abstract)
class UIslandStormdrainHazardousWaveEffectHandler : UHazeEffectEventHandler
{
	// Called when a new wave starts moving.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaveStartMoving() {}

	// Called when the wave reaches the end.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaveReachEnd() {}

	// Called when the wave impacts a platform
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaveImpactPlatform(FHazardousWavePlatformImpactParams ImpactParams) {}

	// Called when the wave is finally turned off.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShutDown() {}
}