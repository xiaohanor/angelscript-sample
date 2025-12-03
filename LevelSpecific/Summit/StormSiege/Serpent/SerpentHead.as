enum ESerpentMovementState
{
	UseSpline,
	TransitionToSpline,
	Stopped
}

enum ESerpentAttackMovementState
{
	FlyForward,
	HoverAttack,
	SpikeRoll
}

event void
FOnSerpentTeleported();
event void FOnSerpentLightningSpewFinished();

struct FSerpentHeadRespawnPointData
{
	UPROPERTY(EditAnywhere)
	ARespawnPoint AttachRespawnPoint;

	UPROPERTY(EditAnywhere)
	int ArmorIndex = 0;
}

struct FSerpentHeadWeakpointData
{
	UPROPERTY(EditAnywhere)
	AStoneBossWeakpointCover AttachWeakpoint;

	UPROPERTY(EditAnywhere)
	int ArmorIndex = 0;
}

struct FSerpentHurtRotationResponse
{
	float FullRotationDistance;
	float CurrentTraversedDistance = 0.0;
	FRotator FullRotation = FRotator(0, 0, 360);
	FRotator AccumulatedRotation;
	FRotator RotationLeft;
}

struct FSerpentConductorPairParams
{
	UPROPERTY()
	AHazeActor TargetActor1;
	UPROPERTY()
	AHazeActor TargetActor2;
}

struct FSerpentLightningConductorData
{
	UPROPERTY()
	TArray<FSerpentConductorPairParams> Params;
}

UCLASS(Abstract, NotBlueprintable)
class USerpentHeadMovementComponentBase : UActorComponent
{
	void InitializeFullSplinePosition()
	{
	}
}

class ASerpentHead : AHazeActor
{
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams FlyingSequenceParams;
	default FlyingSequenceParams.PlayRate = 1;
	default FlyingSequenceParams.bLoop = true;

	// For overall movement
	ESerpentMovementState SerpentMovementState;
	// For attack movement state (if it turns and hovers for an attack)
	ESerpentAttackMovementState SerpentAttackMovementState;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent HeadCollision;
	default HeadCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default HeadCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase SkeletalMeshBeast;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;

	// Attacks
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SerpentHeadSplineFollowSheet);
	default CapabilityComp.DefaultCapabilities.Add(n"SerpentHeadSpikeRollCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SerpentHeadCrystalBreathCapability");

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	UPROPERTY()
	ASplineActor CurrentSpline;

	UPROPERTY()
	TArray<AStoneBossWeakpointCover> Weakpoints;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASplineActor> SplineActors;

	UPROPERTY(EditAnywhere, Category = "Setup")
	USerpentMovementSettings DefaultMovementSettings;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UCameraShakeBase> CrystalBreathCamShake;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartActive = true;
	bool bIsActive;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bRubberbanding = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bCanTransitionToSplines = true;

	UPROPERTY(EditAnywhere, Category = "Weakpoint 1 Phase")
	APlayerForceSlideVolume SlideVolume;

	bool bStartSlideTransition;

	FOnSerpentTeleported OnSerpentTeleported;

	USerpentMovementSettings CurrentMovementSettings;
	FSplinePosition CurrentSplinePosition;

	float MovementSpeed;
	float RubberbandSpeed;
	float MovementInterpSpeed;

	bool bRunLightningConductor;
	bool bRunLightningRocks;
	bool bRunLightningStrikes;
	bool bRunSpikeRollAttack;
	bool bSpikeSeedDestroyOnImpact;

	bool bRunCrystalBreathAttack;
	bool bUseCrystalBreathAnimsInWaterfall;

	bool bIsInWaterfall;

	bool bIsInRockGap;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASerpentSpikeSeed> SpikeSeedClass;
	TArray<ASerpentSpike> SpikeTargets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (DefaultMovementSettings != nullptr)
			ApplySettings(DefaultMovementSettings, this);

		CurrentMovementSettings = USerpentMovementSettings::GetSettings(this);
		if (bStartActive)
			ActivateSerpent(true);

		if (SlideVolume != nullptr)
			SlideVolume.SetVolumeEnabled(false);

		MovementSpeed = CurrentMovementSettings.BaseMovementSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		TEMPORAL_LOG(this)
			.Sphere("SplinePosition", CurrentSplinePosition.WorldLocation, 1000, FLinearColor::Yellow)
			.DirectionalArrow("UpVector", CurrentSplinePosition.WorldLocation, CurrentSplinePosition.WorldUpVector * 20000, 100, 100, FLinearColor::LucBlue)
			.DirectionalArrow("ForwardVector", CurrentSplinePosition.WorldLocation, CurrentSplinePosition.WorldForwardVector * 20000, 100, 100)
			.DirectionalArrow("RightVector", CurrentSplinePosition.WorldLocation, CurrentSplinePosition.WorldRightVector * 20000, 100, 100, FLinearColor::Green)
			.Value("MovementSpeed", MovementSpeed)
			.Value("RubberbandSpeed", RubberbandSpeed)
			.Value("MovementInterpSpeed", MovementInterpSpeed);
#endif
	}

	// float GetCurrentDistanceAlongSpline()
	// {
	// 	return CurrentSpline.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
	// }

	UFUNCTION()
	void ShootSpikeSeedsAtGroup(ASerpentSpikeGroup SpikeGroup, bool bDestroyOnImpact = false)
	{
		bRunSpikeRollAttack = true;
		SpikeTargets = SpikeGroup.GetSpikes();
		bSpikeSeedDestroyOnImpact = bDestroyOnImpact;
	}

	UFUNCTION()
	void DeactivateHomingMissiles()
	{
	}

	UFUNCTION()
	void DeactivateLightingStrikePhase()
	{
		bRunLightningStrikes = false;
	}

	UFUNCTION()
	void ToggleRockGapFlying(bool bToggleValue)
	{
		bIsInRockGap = bToggleValue;
	}

	UFUNCTION()
	void ToggleWaterfall(bool bEnable)
	{
		bIsInWaterfall = bEnable;
	}

	UFUNCTION(DevFunction)
	void SetCrystalBreathActive(bool bShouldFire, bool bUseWaterfallAnims = false)
	{
		if (bShouldFire)
			SerpentAttackMovementState = ESerpentAttackMovementState::HoverAttack;
		else
			SerpentAttackMovementState = ESerpentAttackMovementState::FlyForward;

		bUseCrystalBreathAnimsInWaterfall = bUseWaterfallAnims;
		bRunCrystalBreathAttack = bShouldFire;
	}

	// Set serpent to new position - initialize only if currently active
	UFUNCTION()
	void SetNewPosition(FVector StartLocation)
	{
		ActorLocation = StartLocation;

		if (bIsActive)
		{
			InitializeFullSplinePosition();

			int SplineIndex = SplineActors.FindIndex(CurrentSpline);
			USerpentHeadEffectHandler::Trigger_OnTransitionToNewSpline(this, FSerpentHeadSplineParams(SplineIndex));
		}

		OnSerpentTeleported.Broadcast();
	}

	UFUNCTION()
	void TransitionToNextSpline(int SplineIndex = -1)
	{
		// Check if we can transition to a new spline
		int CurrentIndex = SplineActors.FindIndex(CurrentSpline);
		if (!SplineActors.IsValidIndex(CurrentIndex + 1))
			return;

		if (SplineIndex < 0)
		{
			CurrentSpline = SplineActors[CurrentIndex + 1];
			USerpentHeadEffectHandler::Trigger_OnTransitionToNewSpline(this, FSerpentHeadSplineParams(CurrentIndex + 1));
		}
		else
		{
			CurrentSpline = SplineActors[SplineIndex];
			USerpentHeadEffectHandler::Trigger_OnTransitionToNewSpline(this, FSerpentHeadSplineParams(SplineIndex));
		}

		SerpentMovementState = ESerpentMovementState::TransitionToSpline;
	}

	void CompleteSplineTransition()
	{
		if (CurrentSpline != nullptr)
		{
			SerpentMovementState = ESerpentMovementState::UseSpline;
			CurrentSplinePosition = CurrentSpline.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		}
		else
		{
			SerpentMovementState = ESerpentMovementState::Stopped;
		}
	}

	UFUNCTION()
	void ApplySerpentSettingsWithBlend(USerpentMovementSettings Settings, float BlendTime, FInstigator Instigator)
	{
		float OldSpeed = MovementSpeed;
		ApplySettings(Settings, Instigator);
		float Difference = Math::Abs(USerpentMovementSettings::GetSettings(this).BaseMovementSpeed - OldSpeed);
		MovementInterpSpeed = Difference / BlendTime;
	}

	UFUNCTION()
	void ClearSerpentSettingsWithBlend(float BlendTime, FInstigator Instigator)
	{
		float OldSpeed = MovementSpeed;
		ClearSettingsByInstigator(Instigator);
		float Difference = Math::Abs(USerpentMovementSettings::GetSettings(this).BaseMovementSpeed - OldSpeed);
		MovementInterpSpeed = Difference / BlendTime;
	}

	UFUNCTION()
	void ActivateSerpent(bool bInitializePosition)
	{
		RemoveActorDisable(this);

		bIsActive = true;

		if (bInitializePosition)
			InitializeFullSplinePosition();
	}

	UFUNCTION()
	void DeactivateSerpent()
	{
		bIsActive = false;
		AddActorDisable(this);
	}

	UFUNCTION()
	void SetRubberbanding(bool bCanRubberband)
	{
		bRubberbanding = bCanRubberband;
	}

	bool HasNextSplineAvailable()
	{
		return SplineActors.FindIndex(CurrentSpline) < (SplineActors.Num() - 1);
	}

	// SERPENT RUN SPECIFIC FUNCTIONS
	UFUNCTION()
	void StartSlideTransition()
	{
		SplineActors[1].ActorLocation = ActorLocation + ActorForwardVector * 500.0;
		SplineActors[1].ActorRotation = ActorForwardVector.ConstrainToPlane(FVector::UpVector).Rotation();

		TransitionToNextSpline(1);
	}

	UFUNCTION()
	void ActivateSlide()
	{
		SlideVolume.SetVolumeEnabled(true);
	}

	UFUNCTION()
	void DeactivateSlideForPlayer(AHazePlayerCharacter Player)
	{
		if (SlideVolume.AffectsPlayer == EHazeSelectPlayer::Both)
		{
			if (Player == Game::Zoe)
				SlideVolume.AffectsPlayer = EHazeSelectPlayer::Mio;
			else if (Player == Game::Mio)
				SlideVolume.AffectsPlayer = EHazeSelectPlayer::Zoe;
		}
		else
		{
			SlideVolume.AffectsPlayer = EHazeSelectPlayer::None;
		}
	}

	UFUNCTION()
	void StartClimbTransition()
	{
		// FVector Forward = RuntimeSpline.GetRotationAtDistance(RuntimeSpline.Length).ForwardVector;
		FVector Forward = CurrentSplinePosition.WorldForwardVector;
		// RuntimeSpline.GetUpDirectionAtSplinePointIndex()
		// RuntimeSpline.Points[RuntimeSpline.Length - 1].
		SplineActors[3].ActorLocation = ActorLocation + Forward * 22000.0;
		SplineActors[3].ActorRotation = FRotator::MakeFromXZ(Forward.ConstrainToPlane(FVector::UpVector), FVector::UpVector);

		TransitionToNextSpline(3);
	}

	UFUNCTION()
	void ActivateObstacleShooting(int NewObstacleCount = 0, int IterationsAllowed = -1, float WaitDuration = 3.0)
	{
	}

	UFUNCTION()
	void DeactivateObstacleShooting()
	{
	}

	FVector GetRandomObstacleSpawnLocation()
	{
		float RandomAmount = 1500.0;
		float RandomZ = Math::RandRange(-RandomAmount, RandomAmount);
		float RandomY = Math::RandRange(-RandomAmount, RandomAmount);

		FVector Offset = ActorRightVector * RandomY;
		Offset += ActorUpVector * RandomZ;
		Offset += ActorForwardVector * 10000.0;
		Offset += FVector::UpVector * 3000.0;

		return ActorLocation + Offset;
	}

	UFUNCTION()
	void ActivateLightningRocks(TArray<AStormCliffRock> Rocks)
	{
		for (AStormCliffRock Rock : Rocks)
		{
			FStormSiegeLightningStrikeParams Params;
			Params.Start = ActorLocation;
			Params.End = Rock.ActorLocation;
			Params.BeamWidth = 2.0;
			Params.NoiseStrength = 4.0;
			UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(this, Params);

			Rock.ActivateCliffRock();
		}
	}

	protected void InitializeFullSplinePosition()
	{
		auto MoveComp = USerpentHeadMovementComponentBase::Get(this);
		MoveComp.InitializeFullSplinePosition();
	}
}