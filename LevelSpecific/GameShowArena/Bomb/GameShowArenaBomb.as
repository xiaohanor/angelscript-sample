event void FGameShowArenaBombHoldingEvent(AHazePlayerCharacter Player);
event void FGameShowArenaBombExplodedEvent(AGameShowArenaBomb Bomb);
event void FGameShowArenaBombThrownEvent(AHazePlayerCharacter Player);
event void FGameShowArenaBombOnThrowStartedEvent(AGameShowArenaBomb Bomb);
event void FGameShowArenaBombUnfrozenEvent();

struct FGameShowArenaBombHomingLaunchParams
{
	TArray<FVector> Points;
	float TravelTime;
	bool bIsValid = false;
	AHazePlayerCharacter TargetPlayer;
	FGameShowArenaBombHomingLaunchParams(AHazePlayerCharacter InTargetPlayer, TArray<FVector>& InPoints, float InTravelTime)
	{
		TargetPlayer = InTargetPlayer;
		Points = InPoints;
		TravelTime = InTravelTime;
		bIsValid = true;
	}
	FGameShowArenaBombHomingLaunchParams(TArray<FVector>& InPoints, float InTravelTime)
	{
		TargetPlayer = nullptr;
		Points = InPoints;
		TravelTime = InTravelTime;
		bIsValid = true;
	}
	void Invalidate()
	{
		bIsValid = false;
	}
}

enum EGameShowArenaBombState
{
	Frozen,
	Thawed,
	Exploding,
	Thrown,
	Caught,
	Held,
	Disposed
}

event void FGameShowArenaNetBombCaughtEvent(FVector CatchLocation);
class AGameShowArenaBomb : AHazeActor
{
	access ReadOnly = private, *(readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SetCollisionProfileName(n"BlockAllDynamic");
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Collision)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent InsideMesh;
	default InsideMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent BombTrailVFX;
	default BombTrailVFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UStaticMeshComponent SimulatedMesh;
	default SimulatedMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = SimulatedMesh)
	UStaticMeshComponent SimulatedInsideMesh;
	default SimulatedInsideMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = SimulatedMesh)
	UNiagaraComponent SimBombTrailVFX;
	default SimBombTrailVFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	USweepingMovementData Movement;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombTrajectoryMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombHeldCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombContactExplosionCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombCaughtCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombExplodeResetCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombIdleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombInteriorUpdaterCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombTimeoutExplosionCapability");

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComponent;

	UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UGameShowArenaBombTossGrapplePointComponent GrappleToComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeSphereComponent AirborneHazeSphere;

	UPROPERTY()
	FGameShowArenaBombHoldingEvent OnStartHolding;

	UFUNCTION(BlueprintEvent)
	void BP_OnBombHeldTick() {};

	UPROPERTY()
	FGameShowArenaBombThrownEvent OnBombThrown;

	UPROPERTY()
	FGameShowArenaBombExplodedEvent OnBombStartExploding;

	UPROPERTY()
	FGameShowArenaBombExplodedEvent OnBombExploded;

	UPROPERTY()
	FGameShowArenaBombUnfrozenEvent OnBombUnfrozen;

	UPROPERTY()
	FGameShowArenaBombOnThrowStartedEvent OnThrowStarted;

	UPROPERTY()
	FGameShowArenaNetBombCaughtEvent OnNetBombCaught;

	UPROPERTY(EditAnywhere)
	bool bGrappleTowardsEachOtherRequiresAirborne = true;

	UPROPERTY()
	TSubclassOf<AGameShowArenaBombExplosion> BombExplosionClass;

	UPROPERTY()
	FText TutorialTextBomb;

	FVector SpawnLocation;

	private float ExplodeTimerDuration = 8;
	float TimeUntilExplosion = ExplodeTimerDuration;
	// access:ReadOnly bool bIsThrown = false;
	// access:ReadOnly bool bHasExploded = false;
	// access:ReadOnly bool bIsFrozen = true;
	access:ReadOnly bool bWasLaunchedWithoutTarget = false;
	access:ReadOnly TInstigated<EGameShowArenaBombState> State;

	bool bIsCaught = false;
	bool bIsAttached = false;
	bool bResetExplodeTimer = false;

	bool bHasFoundClosePlayer = false;

	private TInstigated<bool> InstigatedExplosionBlock;

	AHazePlayerCharacter Thrower;
	AHazePlayerCharacter Holder;

	TInstigated<bool> MovementBlockers;
	TInstigated<bool> GameplayBlockers;

	int SpawnExplosionCounter = 0;

	FGameShowArenaBombHomingLaunchParams HomingLaunchParams;

	FVector TrajectoryLaunchVelocity;

	UMaterialInstanceDynamic MeshFillMaterialInstance;
	UMaterialInstanceDynamic SimulatedMeshFillMaterialInstance;

	/* ForceFeedback */
	private float AudioEnvelopeValue = 0;

	float CountdownFFTimer = 0;
	float CountdownFFTimerDuration = 60.0/58.0;

	bool bFFCountdownStarted = false;
	bool bAudioEnvelopeActive = false;

	UPROPERTY()
	UCurveFloat CountdownFFCurve;
	/* --- */

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if EDITOR
		GameShowArena::DisableExplosionTimer.MakeVisible();
#endif
		// SimulatedMesh.AddComponentVisualsBlocker(VisualInstigator);
		SpawnLocation = ActorLocation;
		this.JoinTeam(n"BombTossTeam");

		if (!Network::IsGameNetworked())
		{
			ShowNonProxyMeshes();
		}

		int Index = Mesh.GetMaterialIndex(n"GameShowPanel_01_Scalar");
		MeshFillMaterialInstance = Mesh.CreateDynamicMaterialInstance(Index);
		Index = SimulatedMesh.GetMaterialIndex(n"GameShowPanel_01_Scalar");
		SimulatedMeshFillMaterialInstance = SimulatedMesh.CreateDynamicMaterialInstance(Index);

		SetActorEnableCollision(false);
		AirborneHazeSphere.SetVisibility(false);
	}

	UFUNCTION(NetFunction)
	void NetCatchBomb(FVector Location)
	{
		OnNetBombCaught.Broadcast(Location);
	}

	float GetFillAlpha()
	{
		return MeshFillMaterialInstance.GetScalarParameterValue(n"FuelAlpha");
	}

	FVector GetFillColor()
	{
		FLinearColor Color = MeshFillMaterialInstance.GetVectorParameterValue(n"MeterColor");
		return FVector(Color.R, Color.G, Color.B);
	}

	void UpdateFillMaterial(float FuelAlpha, FVector Color)
	{
		MeshFillMaterialInstance.SetScalarParameterValue(n"FuelAlpha", FuelAlpha);
		MeshFillMaterialInstance.SetVectorParameterValue(n"MeterColor", FLinearColor(Color.X, Color.Y, Color.Z));
		SimulatedMeshFillMaterialInstance.SetScalarParameterValue(n"FuelAlpha", FuelAlpha);
		SimulatedMeshFillMaterialInstance.SetVectorParameterValue(n"MeterColor", FLinearColor(Color.X, Color.Y, Color.Z));
	}

	void ShowProxyMeshes()
	{
		AirborneHazeSphere.AttachToComponent(SimulatedMesh);
		SimulatedMesh.SetVisibility(true, true);
		Mesh.SetVisibility(false, true);
	}

	void ShowNonProxyMeshes()
	{
		AirborneHazeSphere.AttachToComponent(Mesh);
		Mesh.SetVisibility(true, true);
		SimulatedMesh.SetVisibility(false, true);
	}

	bool HasExplosionBlock() const
	{
		return InstigatedExplosionBlock.Get();
	}

	void ApplyBlockExplosion(FInstigator Instigator, EInstigatePriority Priority)
	{
		InstigatedExplosionBlock.Apply(true, Instigator, Priority);
	}

	void ClearBlockExplosion(FInstigator Instigator)
	{
		InstigatedExplosionBlock.Clear(Instigator);
	}

	void ApplyState(EGameShowArenaBombState NewState, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		State.Apply(NewState, Instigator, Priority);
	}

	void ClearState(FInstigator Instigator)
	{
		State.Clear(Instigator);
	}

	void ShowRealMesh(FInstigator Instigator)
	{
		Mesh.RemoveComponentVisualsBlocker(Instigator);
		SimulatedMesh.AddComponentVisualsBlocker(Instigator);
	}

	/** 0:1, 0 is when bomb is caught, 1 is when bomb explodes.*/
	UFUNCTION(BlueprintPure)
	float GetBombLifetimeAlpha()
	{
		return 1 - Math::Saturate(TimeUntilExplosion / ExplodeTimerDuration);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BombFFCountdown(DeltaSeconds);

		if (!bHasFoundClosePlayer)
		{
			if (!Game::Mio.IsPlayerDead() && !Game::Zoe.IsPlayerDead())
			{
				if (GetSquaredDistanceTo(Game::Mio) < GetSquaredDistanceTo(Game::Zoe))
				{
					SetActorControlSide(Game::Mio);
				}
				else
				{
					SetActorControlSide(Game::Zoe);
				}
				bHasFoundClosePlayer = true;
			}
		}
#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("Thrower", Thrower);
		TemporalLog.Value("Holder", Holder);
		TemporalLog.Value("State", State.Get());
		TArray<FString> DisableInstigators;
		GetDisableInstigatorsDebugInformation(DisableInstigators);
		for (int i = 0; i < DisableInstigators.Num(); i++)
		{
			TemporalLog.Value(f"DisableInstigators;{i}", DisableInstigators[i]);
		}
#endif
	}

	UFUNCTION(CrumbFunction)
	void CrumbUnfreeze()
	{
		ApplyState(EGameShowArenaBombState::Thawed, this);
		DetachFromActor();
		OnBombUnfrozen.Broadcast();
		HideTutorial();
	}

	UFUNCTION(BlueprintPure)
	float GetTimeUntilExplosion() const
	{
		return TimeUntilExplosion;
	}

	UFUNCTION(BlueprintPure)
	float GetMaxExplodeTimerDuration() const
	{
		return ExplodeTimerDuration;
	}

	UFUNCTION()
	void SetExplodeTimerDuration(float Duration)
	{
		ExplodeTimerDuration = Duration;
	}

	UFUNCTION()
	void StartThrow()
	{
		OnThrowStarted.Broadcast(this);
	}

	void ResetTimeToExplode()
	{
		bResetExplodeTimer = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplode(FVector Location)
	{
		// UnblockCollision();
		auto Explosion = SpawnActor(BombExplosionClass, Location, FRotator::ZeroRotator, NAME_None, bDeferredSpawn = true);
		Explosion.MakeNetworked(this, SpawnExplosionCounter);
		SpawnExplosionCounter += 1;
		FinishSpawningActor(Explosion);
		OnBombStartExploding.Broadcast(this);
		Timer::SetTimer(this, n"OnBombExplosion", 0.5);
		DetachFromActor();
		Thrower = nullptr;
		Holder = nullptr;
		bWasLaunchedWithoutTarget = false;
		bIsAttached = false;
		HomingLaunchParams.Invalidate();
		bFFCountdownStarted = false;
		ClearState(this);
		ApplyState(EGameShowArenaBombState::Exploding, this, EInstigatePriority::EInstigatePriority_MAX);
		BP_Explode();

		if (HasControl() && !MovementBlockers.Get())
		{
			BlockCapabilities(CapabilityTags::Movement, this);
			BlockCapabilities(CapabilityTags::GameplayAction, this);
			MovementBlockers.Apply(true, this);
			GameplayBlockers.Apply(true, this);
		}

		AddActorVisualsBlock(this);

		for (auto Player : Game::Players)
		{
			UGameShowArenaBombTossPlayerComponent::Get(Player).HandleOnBombStartExploding();
			UGameShowArenaBombTossEventHandler::Trigger_OnPlayerBombExploded(Player, FGameShowArenaPlayerBombExplodedParams(Player));
		}

		GameShowArena::OnBombExploded();

		// AddActorDisable(this);
	}

	UFUNCTION()
	private void OnBombExplosion()
	{
		OnBombExploded.Broadcast(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbRespawn()
	{
		bHasFoundClosePlayer = false;
		SetActorEnableCollision(false);
		ClearState(this);
		ApplyState(EGameShowArenaBombState::Frozen, this);
		bWasLaunchedWithoutTarget = false;
		bIsAttached = false;
		Thrower = nullptr;
		Holder = nullptr;
		TimeUntilExplosion = ExplodeTimerDuration;
		RemoveActorVisualsBlock(this);
		// RemoveActorDisable(this);
		if (HasControl())
		{
			SetActorLocation(SpawnLocation);

			if (MovementBlockers.Get())
			{
				UnblockCapabilities(CapabilityTags::Movement, this);
				MovementBlockers.Clear(this);
			}
			if (GameplayBlockers.Get())
			{
				UnblockCapabilities(CapabilityTags::GameplayAction, this);
				GameplayBlockers.Clear(this);
			}
		}
	}

	float GetVelocityMagnitude() const property
	{
		return MovementComponent.Velocity.Size();
	}

	void ShowTutorial(AHazePlayerCharacter Player)
	{
		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::WeaponFire;
		Prompt.Text = TutorialTextBomb;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Player.ShowTutorialPromptWorldSpace(Prompt, this, Mesh, AttachOffset = FVector(0, 0, -40));
	}

	void HideTutorial()
	{
		for(auto Player : Game::Players)
			Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunch(AHazePlayerCharacter ThrowingPlayer, FGameShowArenaBombHomingLaunchParams Params)
	{
		FGameShowArenaPlayerThrowBombAtPlayerParams EventParams;
		EventParams.Bomb = this;
		EventParams.ThrowingPlayer = ThrowingPlayer;
		UGameShowArenaBombTossEventHandler::Trigger_OnPlayerThrowBombAtOtherPlayer(ThrowingPlayer, EventParams);
		// UnblockCollision();
		Thrower = ThrowingPlayer;
		DetachFromActor();
		Holder = nullptr;
		BP_Throw();
		ApplyState(EGameShowArenaBombState::Thrown, this, EInstigatePriority::Normal);
		OnBombThrown.Broadcast(ThrowingPlayer);
		SetActorEnableCollision(true);
		HomingLaunchParams = Params;
		bIsAttached = false;
		bFFCountdownStarted = false;
		UGameShowArenaBombTossPlayerComponent::Get(ThrowingPlayer.OtherPlayer).bHasIncomingBomb = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbTrajectoryLaunch(AHazePlayerCharacter ThrowingPlayer, FVector Velocity)
	{
		FGameShowArenaPlayerThrowBombNoTargetParams EventParams;
		EventParams.Bomb = this;
		EventParams.ThrowingPlayer = ThrowingPlayer;
		UGameShowArenaBombTossEventHandler::Trigger_OnPlayerThrowBombNoTarget(ThrowingPlayer, EventParams);

		// UnblockCollision();
		Thrower = ThrowingPlayer;
		DetachFromActor();
		Holder = nullptr;
		BP_Throw();
		ApplyState(EGameShowArenaBombState::Thrown, this, EInstigatePriority::Normal);
		OnBombThrown.Broadcast(ThrowingPlayer);
		SetActorEnableCollision(true);
		bWasLaunchedWithoutTarget = true;
		TrajectoryLaunchVelocity = Velocity;
		bIsAttached = false;
		UGameShowArenaBombTossPlayerComponent::Get(ThrowingPlayer.OtherPlayer).bHasIncomingBomb = false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbCatch(AHazePlayerCharacter Catcher)
	{
		Holder = Catcher;
		ApplyState(EGameShowArenaBombState::Caught, this, EInstigatePriority::High);
		GrappleToComp.bIsAutoAimEnabled = false;
		// MovementComponent.Reset(true);
		BP_BombCaught(false);
		bWasLaunchedWithoutTarget = false;
		// ResetTimeToExplode();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartHolding()
	{
		ClearState(this);
		ApplyState(EGameShowArenaBombState::Held, this, EInstigatePriority::High);
		GrappleToComp.bIsAutoAimEnabled = false;
		MovementComponent.Reset(true);
		BP_BombCaught(false);
		bWasLaunchedWithoutTarget = false;
		bFFCountdownStarted = true;
	}

	void AudioEnvelopeStart()
	{
		bAudioEnvelopeActive = true;
		BP_FFCountDown();
	}

	void AudioEnvelopeStop()
	{
		bAudioEnvelopeActive = false;
	}

	void SetAudioEnvelopeValue(float InValue)
	{
		AudioEnvelopeValue = InValue;
		float BpmMultiplier = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(1, 8), CountdownFFCurve.GetFloatValue(AudioEnvelopeValue));
		CountdownFFTimerDuration = 60.0 / (58.0 * BpmMultiplier);
	}

	void BombFFCountdown(float DeltaTime)
	{
		if(!bFFCountdownStarted || !bAudioEnvelopeActive)
			return;

		CountdownFFTimer += DeltaTime;
		if(CountdownFFTimer >= CountdownFFTimerDuration)
		{
			CountdownFFTimer = 0;
			BP_FFCountDown();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_FFCountDown()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_Throw()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_BombCaught(bool bCatcherIsThrower)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_Grapple()
	{
	}

	UFUNCTION(BlueprintEvent)
	void OnChangeBallColor(FLinearColor NewColor)
	{}
}