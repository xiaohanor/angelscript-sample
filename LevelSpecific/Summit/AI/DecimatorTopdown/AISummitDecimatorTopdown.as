event void FOnDecimatorDie();
event void FSummitDecimatorPhaseThreeEvent();
event void FSummitDecimatorPhaseFourEvent();
event void FOnSummitDecimatorBothPlayersBit();

UCLASS(Abstract)
class AAISummitDecimatorTopdown : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownSpinChargeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownTakeDamageCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownJumpCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownShockwaveJumpCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownZoeControlledSpawnerCapability"); // this sets control side to Zoe's side.
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownSpawnerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownSpinSpikebombSpawnerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownPlayerTrapSpawnerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownPauseCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownPatternSpearSpawnerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownSpinBalconyCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownSpinBeamCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownInterruptCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownSpinningStumbleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownPermaKnockedOutCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownKnockedOutCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorKnockedOutRecoverCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownSpearAnimCapability");

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	USceneComponent JumpDestination; // Jump down to this point from platform

	UPROPERTY(DefaultComponent)
	USummitDecimatorTopdownPhaseComponent PhaseComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	USummitDecimatorTopdownMeltComponent MeltComp;
	default MeltComp.bMeltAllMaterials = false;
	default MeltComp.MeltMaterialIndex = 2;

	// Initially start as hidden. Mesh is set to visible in the SpearAnimCapability. Set to visible in new capability if SpearAnimCapability is deprecated.
	default Mesh.SetHiddenInGame(true);
	
	UPROPERTY(DefaultComponent, Attach="CharacterMesh0")
	UPoseableMeshComponent PoseableMesh;
	default PoseableMesh.SetHiddenInGame(true);
	default PoseableMesh.SetCollisionProfileName(n"NoCollision");
	default PoseableMesh.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	UAcidResponseComponent AcidResponseComp;
	default AcidResponseComp.Shape = FHazeShapeSettings::MakeSphere(250);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	UCapsuleComponent HeadCapsuleComponent;
	default HeadCapsuleComponent.bGenerateOverlapEvents = false;
	default HeadCapsuleComponent.CollisionProfileName = n"EnemyIgnoreCharacters";

	// For detecting player hits in spincharge attack.
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Crystal")
	UCapsuleComponent SpinchargeCapsuleComponent;
	default SpinchargeCapsuleComponent.bGenerateOverlapEvents = false;
	default SpinchargeCapsuleComponent.CollisionProfileName = n"NoCollision";
	default SpinchargeCapsuleComponent.CapsuleHalfHeight = 350;
	default SpinchargeCapsuleComponent.CapsuleRadius = 350;

	// For preventing player passing through decimator while not in spincharge.
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Crystal")
	UCapsuleComponent BlockPlayerCapsuleComponent;
	default BlockPlayerCapsuleComponent.bGenerateOverlapEvents = false;
	default BlockPlayerCapsuleComponent.CollisionProfileName = n"EnemyIgnoreCharacters";
	default BlockPlayerCapsuleComponent.CapsuleHalfHeight = 450;
	default BlockPlayerCapsuleComponent.CapsuleRadius = 450;

	// SpikeBomb Spawning
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnerComponent SpawnerComp;
	default SpawnerComp.bStartActivated = true;

	UPROPERTY(DefaultComponent, EditDefaultsOnly)
	UHazeActorSpawnPatternInterval SpikeBombSpawnPattern;
	default SpikeBombSpawnPattern.bStartActive = false;

	// Special case for spawning spikebombs in phase 3
	UPROPERTY(DefaultComponent, EditDefaultsOnly)
	UHazeActorSpawnPatternInterval SpinSpikeBombSpawnPattern;
	default SpinSpikeBombSpawnPattern.bStartActive = false;
	
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASummitDecimatorTopdownPlayerTrap> PlayerTrapClass;

	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternInterval SpearSpawnPattern;
	default SpearSpawnPattern.bStartActive = false;

	UPROPERTY(DefaultComponent)
	USummitDecimatorTopdownPlayerTargetComponent TargetComp;

	UPROPERTY(DefaultComponent)
	USummitDecimatorTopdownShockwaveLauncherComponent ShockwaveLauncherComp;
	
	// Follow spline in phase 4
	UPROPERTY(DefaultComponent)
	USummitDecimatorTopdownFollowSplineComponent SplineComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeActorLocalSpawnPoolComponent ExplosionTrailSpawnPool;

	UPROPERTY(EditAnywhere)
	UMaterialInterface InvulnerableOverlayMaterial;

	UPROPERTY(EditAnywhere)
	TArray<AScenepointActor> SpearSpawnPoints;

	UPROPERTY(EditAnywhere)
	ASummitDecimatorMiddlePlatform MiddlePlatform;
	
	UPROPERTY(EditAnywhere)
	ASummitDecimatorSpinBeam SpinBeam;

	UPROPERTY(EditAnywhere)
	ASummitDecimatorBalcony BalconyPlatform;

	FVector ArenaCenterLocation;

	// Tail components
	UPROPERTY(DefaultComponent, Attach = "HeadCapsuleComponent")
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;
	default TailAttackResponseComp.bIsPrimitiveParentExclusive = true;
	default TailAttackResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	UAutoAimTargetComponent AutoAimComp;
	default AutoAimComp.AutoAimMaxAngle = 25.0;
	default AutoAimComp.bIsAutoAimEnabled = false;

	UPROPERTY(DefaultComponent, Attach ="MeshOffsetComponent")
	UInteractionComponent LeftDragInteractionComp;
	default LeftDragInteractionComp.bPlayerCanCancelInteraction = false;
	default LeftDragInteractionComp.InteractionCapability = n"SummitDecimatorTopdownPlayerDragInteractionCapability";

	UPROPERTY(DefaultComponent, Attach ="MeshOffsetComponent")
	UInteractionComponent RightDragInteractionComp;
	default RightDragInteractionComp.bPlayerCanCancelInteraction = false;
	default RightDragInteractionComp.InteractionCapability = n"SummitDecimatorTopdownPlayerDragInteractionCapability";

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent PlayerRequestComp;
	default PlayerRequestComp.InitialStoppedSheets_Zoe.Add(TeenDragonRollOverlapTraceSheet);
	
	UPROPERTY(DefaultComponent)
	USummitDecimatorTopdownSpearLauncherComponent SpearLauncherComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

 	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASummitDecimatorSpikeBombExplosionTrail> SpikebombExplosionTrailSpawnClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShakeLight;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShakeHeavy;

	UPROPERTY(EditInstanceOnly)
	ASummitDecimatorTopdownSpearManager SpearManager;

	UPROPERTY(BlueprintReadOnly)
	ASummitDecimatorTopdownPlayerTrap PlayerTrap;

	FVector HomeLocation;

	UPROPERTY()
	FOnDecimatorDie OnDecimatorDie; // TODO: replace with OnDecimatorTakeRollHitDamage

	UPROPERTY()
	FSummitDecimatorPhaseThreeEvent OnPhaseThreeStart;

	UPROPERTY()
	FSummitDecimatorPhaseFourEvent OnPhaseFourStart;

	UPROPERTY()
	FOnSummitDecimatorBothPlayersBit OnBothPlayersBit;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve EntryJumpCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ShockwaveJumpCurve;

	bool bIsTurningOutward = false;
	float SpinningDir = 1.0;

	USummitDecimatorSpikeBombSettings SpikeBombSettings;

	bool bHasStartedRollTraceSheet = false;
	bool bHasIgnoredDragons = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UBasicAIMovementSettings::SetTurnDuration(this, 30, this, EHazeSettingsPriority::Gameplay);
		UMovementGravitySettings::SetGravityScale(this, 1000, this, EHazeSettingsPriority::Defaults);		
		ExplosionTrailSpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(SpikebombExplosionTrailSpawnClass, this);
		UHazeTeam DecimatorTeam = JoinTeam(DecimatorTopdownTags::DecimatorTeamTag);
		if (DecimatorTeam.GetMembers().Num() > 1) // this ought not happen since LeaveTeam is called in EndPlay.
			DecimatorTeam.RemoveMember(nullptr);
		HomeLocation = ActorLocation;
		ArenaCenterLocation = AttachmentRootActor.ActorLocation;
		SpikeBombSettings = USummitDecimatorSpikeBombSettings::GetSettings(this);
		
		// Set facing towards arena center point
		AActor ArenaCenterScenePoint = AttachmentRootActor;
		FVector ArenaCenterDir = (ArenaCenterScenePoint.ActorLocation - ActorLocation).GetSafeNormal2D();
		SetActorRotation(ArenaCenterDir.Rotation());

		// Prevent stepping up on player, tail and all.
		for (AHazePlayerCharacter Player : Game::Players)
			MoveComp.AddMovementIgnoresActor(this, Player);

		MeltComp.OnMelted.AddUFunction(this, n"OnMelted");
	}

	UFUNCTION()
	private void OnMelted()
	{		
		USummitDecimatorTopdownEffectsHandler::Trigger_OnHeadMelted(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(DecimatorTopdownTags::DecimatorTeamTag);

		if(bHasStartedRollTraceSheet)
			PlayerRequestComp.StopInitialSheetsAndCapabilities(Game::Zoe, this);
	}


	FHazeAcceleratedVector AccMeshOffset;
	bool bHasBeenHit = false;
	FVector SpikeBombHitDirection;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if (bHasBeenHit && PhaseComp.CurrentState != ESummitDecimatorState::KnockedOut)
		{
			AccMeshOffset.SpringTo(FVector(0, 100, 	50), 1000, 0, DeltaSeconds);
			Mesh.SetRelativeLocation(AccMeshOffset.Value);
			if (AccMeshOffset.Value.Y > 99)
			{
				bHasBeenHit = false;
				SpikeBombHitDirection = FVector::ZeroVector;
			}
		}
		else
		{
			bHasBeenHit = false;
			AccMeshOffset.SpringTo(FVector(0,0,0), 1000, 0, DeltaSeconds);
			Mesh.SetRelativeLocation(AccMeshOffset.Value);				
		}

		if (!bHasIgnoredDragons)
		{
			ATeenDragon AcidDragon = TeenDragon::GetPlayerTeenDragon(Game::Mio);
			ATeenDragon TailDragon = TeenDragon::GetPlayerTeenDragon(Game::Zoe);
			if (AcidDragon != nullptr && TailDragon != nullptr)
			{
				MoveComp.AddMovementIgnoresActor(this, AcidDragon);
				MoveComp.AddMovementIgnoresActor(this, TailDragon);
				bHasIgnoredDragons = true;
			}
		}
	}
		
	// OnSpikeBombHit is called from a crumbed function.
	void OnSpikeBombHit(AHazeActor Instigator, FVector HitDirection = FVector::ZeroVector)
	{	
		// Prevent taking damage in jump down. Will also prevent taking damage in knockdown state and before battle start.
		if (PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
		 	return;

		// Take damage, but save some for the final roll hit.
		UBasicAIHealthComponent AIHealthComp = UBasicAIHealthComponent::Get(this);
		if (AIHealthComp.CurrentHealth > SpikeBombSettings.DecimatorMinHealthLimit + SMALL_NUMBER)
		{
			// Handle the case when damage per hit is higher than the min health limit.
			float RemainingHealth = AIHealthComp.CurrentHealth - SpikeBombSettings.DecimatorDetonationExplosionDamage;

			if (RemainingHealth > SpikeBombSettings.DecimatorMinHealthLimit)
			{
				float Damage = SpikeBombSettings.DecimatorDetonationExplosionDamage;
				Damage::AITakeDamage(this, Damage, Instigator, EDamageType::Explosion);
			}
			else
			{
				AIHealthComp.SetCurrentHealth(SpikeBombSettings.DecimatorMinHealthLimit);
				// Blink the healthbar
				Damage::AITakeDamage(this, 0.0, Instigator, EDamageType::Explosion);
			}
		}

		DamageFlash::DamageFlashActor(this, 0.5);

		USummitDecimatorTopdownEffectsHandler::Trigger_OnHitBySpikebomb(this);

		// TODO: Request hit reaction sub feature, instigator must match		
		//AnimComp.RequestSubFeature(SubTagSummitDecimatorAttack::SpinTakeDamage, this);

		PhaseComp.OnSpikeBombHit(); // PhaseComp will phase transition after certain number of hits		
		Game::Mio.PlayCameraShake(CameraShakeLight, this);
		Game::Zoe.PlayCameraShake(CameraShakeLight, this);
		bHasBeenHit = true;
		SpikeBombHitDirection = HitDirection;
	}

	UFUNCTION(DevFunction)
	void DevTestCameraShake()
	{
		Game::Mio.PlayCameraShake(CameraShakeLight, this);
		Game::Zoe.PlayCameraShake(CameraShakeLight, this);
	}

	// Called from BossArena_BP for every phase progression point. Only once with natural progression.
	UFUNCTION()
	void OnBeginBattle()
	{
		ApplyDefaultSettings(SummitDecimatorTopdownHealthBarSettings);
		HealthBarComp.UpdateHealthBarSettings();
		PhaseComp.ChangeState(ESummitDecimatorState::RunningAttackSequence);

		PlayerRequestComp.StartInitialSheetsAndCapabilities(Game::Zoe, this);
		bHasStartedRollTraceSheet = true;
	}

	UFUNCTION()
	void OnBeginPhaseOne()
	{
		USummitDecimatorTopdownEffectsHandler::Trigger_OnBeginPhaseOne(this);
	}

	UFUNCTION()
	void BeginPhaseThree()
	{
		// Setup phase for progress point
		PhaseComp.ActivatePhase(3);

		// Setup health state for progress point
		Damage::AITakeDamage(this, SpikeBombSettings.DecimatorDetonationExplosionDamage * PhaseComp.NumSpikeBombHits, this, EDamageType::Explosion);
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	void DevBeginPhaseFour()
	{
		BeginPhaseFour();
	}

	UFUNCTION()
	void BeginPhaseFour()
	{
		// Setup phase for progress point
		PhaseComp.ActivatePhase(4);
		SetActorLocation(AttachmentRootActor.ActorLocation);
		PhaseComp.NumSpikeBombHits = PhaseComp.Settings.PhaseOneNumSpikeBombHits + PhaseComp.Settings.PhaseTwoNumSpikeBombHits + 3; // arbitrary
		PhaseComp.CurrentPhase = 4;
		PhaseComp.ChangeState(ESummitDecimatorState::PermaKnockedOut);
		PhaseComp.ResetAttackSequence();
		Mesh.SetHiddenInGame(false);
		//OnPhaseFourStart.Broadcast(); // This is already called in PhaseComp.ActivatePhase()
	}

	UFUNCTION()
	void PlayRoarAnimation()
	{
		DecimatorTopdown::Animation::RequestFeatureRoar(AnimComp, this);
	}

	UFUNCTION()
	void KnockOut()
	{
		PhaseComp.ChangeState(ESummitDecimatorState::KnockedOut);
	}

	UFUNCTION()
	void ClearRoarAnimation()
	{
		AnimComp.ClearFeature(this);
	}
	
	// This will activate the SpearAnimCapability and show the mesh.
	UFUNCTION()
	void InitCombatReady()
	{
		PhaseComp.CurrentState = ESummitDecimatorState::Idle;
	}

	UFUNCTION(DevFunction)
	void DevBeginBattle()
	{
		OnBeginBattle();
	}

	UFUNCTION(DevFunction)
	void DevKnockOut()
	{
		KnockOut();
	}


	UFUNCTION(DevFunction)
	void DevPlayRoarAnimation()
	{
		PlayRoarAnimation();
		Timer::SetTimer(this, n"ClearRoarAnimation", 1.0);
	}

	UFUNCTION(DevFunction)
	void DevTakeSpikeBombHit()
	{
		OnSpikeBombHit(this);
	}

	UFUNCTION(DevFunction)
	void DevImmediateMeltHead()
	{
		MeltComp.ImmediateMelt();
	}

	UFUNCTION(DevFunction)
	void DevImmediateMeltSpikebombs()
	{
		UHazeTeam SpikeBombTeam = HazeTeam::GetTeam((DecimatorTopdownSpikeBombTags::SpikeBombTeamTag));
		if (SpikeBombTeam != nullptr)
		{
			for (AHazeActor Member : SpikeBombTeam.GetMembers())
			{
				if (Member == nullptr)
					continue;
								
				// Enable explosion
				USummitMeltComponent SpikebombMeltComp = USummitMeltComponent::Get(Member);
				if (SpikebombMeltComp != nullptr)
					SpikebombMeltComp.ImmediateMelt();
			}
		}
	}

	UFUNCTION(DevFunction)
	void DevToggleDebugFlag()
	{
		bHazeEditorOnlyDebugBool = !bHazeEditorOnlyDebugBool;
		Print("Debugflag is: " +bHazeEditorOnlyDebugBool, Color=FLinearColor::Green);
	}

}

namespace DecimatorTopdownTags
{
	const FName DecimatorTeamTag = n"DecimatorTeam";
}

asset SummitDecimatorTopdownHealthBarSettings of UBasicAIHealthBarSettings
{
	HealthBarVisibility = EBasicAIHealthBarVisibility::AlwaysShow;
}
