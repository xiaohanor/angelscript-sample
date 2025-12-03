class ASanctuaryBossArenaFloatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UFauxPhysicsAxisRotateComponent RotateComp1;

	UPROPERTY(DefaultComponent, Attach = RotateComp1)
	UFauxPhysicsAxisRotateComponent RotateComp2;

	UPROPERTY(DefaultComponent, Attach = RotateComp2)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UNiagaraComponent WaveSplashVFXComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComponent;

	UPROPERTY()
	UNiagaraSystem BreakPlatformVFX;

	UPROPERTY(EditAnywhere)
	float ArenaRadius = 17000.0;

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = false;
	bool bHasSetup = false;

	bool bReturnPlatform = false;
	float ReturnTargetHeight = 0.0;

	FHazeAcceleratedFloat AccHeightAfterCrunched;

	bool bRegisteredAviation = false;
	bool bCrunched = false;

	bool bIsOnZoeSide = true;
	
	UPROPERTY(EditAnywhere)
	bool bShouldSnap = true;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (AttachParentActor != nullptr)
		{
			
			FVector Direction = (ActorLocation - AttachParentActor.ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		
			if(bShouldSnap)
			{
				SetActorLocation(Direction * ArenaRadius + FVector::UpVector * ActorLocation.Z);
				SetActorRotation(Direction.Rotation());
			}
				
			
			FVector DeltaScale = ActorScale3D - FVector::OneVector;

			PlatformRoot.SetRelativeScale3D(PlatformRoot.RelativeScale3D + DeltaScale);

			SetActorScale3D(FVector::OneVector);

			float TorqueBounds = PlatformRoot.RelativeScale3D.Y * 100.0;
			RotateComp1.TorqueBounds = TorqueBounds;
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (auto AttachedActor : AttachedActors)
			AttachedActor.AttachToComponent(PlatformRoot, AttachmentRule = EAttachmentRule::KeepWorld);

		if (ActorLocation.Z < 3100.0) // hardcoded culling
		{
			TListedActors<ASanctuaryBossArenaWave> Waves;
			for (auto Wave : Waves)
				Wave.OnWaveSplash.AddUFunction(this, n"OnWavePass");
		}

		TListedActors<ASanctuaryBossArenaManager> ArenaManagers;
		if (ArenaManagers.Num() == 0) // we're streaming the level probably
			return;
		bIsOnZoeSide = SanctuaryCompanionAviationStatics::IsOnArenaZoeQuad(ArenaManagers.Single, ActorLocation);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bHasSetup)
			LateSetup();

		if (bReturnPlatform)
		{
			AccHeightAfterCrunched.AccelerateTo(ReturnTargetHeight, 4.0, DeltaSeconds);
			FVector Location = ActorLocation;
			Location.Z = AccHeightAfterCrunched.Value;
			SetActorLocation(Location);
			if (Math::IsNearlyEqual(ReturnTargetHeight, AccHeightAfterCrunched.Value, 1.0) && Math::Abs(AccHeightAfterCrunched.Velocity) < 3.0)
				BackInAction();
		}
	}

	private void LateSetup()
	{
		if (bStartDisabled)
		{
			bool bShouldDisable = false;
			TListedActors<ASanctuaryBossArenaHydra> Hydras;
			for (auto Hydra : Hydras)
			{
				if (Hydra.KillCount >= 2)
				{
					bHasSetup = true;
					RemoveActorDisable(this);
				}
				else
				{
					bShouldDisable = true;
					Hydra.OnArenaBossHeadDiedEvent.AddUFunction(this, n"OnHeadDied");
				}
			}

			if (bShouldDisable)
			{
				bHasSetup = true;
				AddActorDisable(this);
			}
		}
		else
		{
			bHasSetup = true;
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void OnHeadDied(int KillCount)
	{
		if (KillCount >= 2)
		{
			RemoveActorDisable(this);
		}
	}

	UFUNCTION()
	void OnWavePass(FVector WaveLocation)
	{
		float SmallestDistance = BIG_NUMBER;
		for (auto Player : Game::GetPlayers())
		{
			float Distance = (Player.ActorLocation - ActorLocation).Size();
			if (Distance < SmallestDistance)
				SmallestDistance = Distance;
		}

		const float CullDistance = 3000.0;
		if (SmallestDistance > CullDistance)
			return;

		FVector ApproxWaveLocation = WaveLocation;
		ApproxWaveLocation.Z += 200.0;
		if (ActorLocation.Z < ApproxWaveLocation.Z)
		{
			FVector WaveHeightLocation = ActorLocation;
			WaveHeightLocation.Z = ApproxWaveLocation.Z;
			WaveSplashVFXComp.Activate(true);
			FVector ImpulseDirection = (ActorLocation - ApproxWaveLocation).GetSafeNormal();
			FauxPhysics::ApplyFauxImpulseToActorAt(this, ActorLocation, ImpulseDirection * 1500.0);
		}
	}

	private void BackInAction()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (int iActor = 0; iActor < AttachedActors.Num(); ++iActor)
		{
			ASanctuaryBossArenaHydraTarget Target = Cast<ASanctuaryBossArenaHydraTarget>(AttachedActors[iActor]);
			if (Target != nullptr)
			{
				Target.bTargetable = true;
				Target.bCruncyTarget = false;
				Target.bCruncyTargeted = false;
			}
		}

		bReturnPlatform = false;
		bCrunched = false;
		SetActorTickEnabled(false);
	}

	UFUNCTION() 
	void Targeted()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (int iActor = 0; iActor < AttachedActors.Num(); ++iActor)
		{
			ASanctuaryBossArenaHydraTarget Target = Cast<ASanctuaryBossArenaHydraTarget>(AttachedActors[iActor]);
			if (Target != nullptr)
				Target.bTargetable = false;
		}
	}

	UFUNCTION()
	void Crunched()
	{
		ReturnTargetHeight = ActorLocation.Z;
		bCrunched = true;

		// Play niagara effect rock thing here
		if (BreakPlatformVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakPlatformVFX, ActorLocation, ActorRotation);

		// Move to beneath water
		// Accelerate back when player aviates
		FVector NewLocation = ActorLocation;
		NewLocation.Z -= 5000.0;
		SetActorLocation(NewLocation);
		AccHeightAfterCrunched.SnapTo(NewLocation.Z);

		if (!bRegisteredAviation)
			AviationHookup();

		if (SanctuaryHydraDevToggles::ReturnBitingPlatforms.IsEnabled())
			Timer::SetTimer(this, n"DebugReturn", 5.0);
	}

	UFUNCTION()
	private void DebugReturn()
	{
		Reset();
	}

	private void AviationHookup()
	{
		bRegisteredAviation = true;
		// On player started aviating event

		RegisterAviationListening(bIsOnZoeSide ? Game::Zoe : Game::Mio);
	}

	private void RegisterAviationListening(AHazePlayerCharacter Player)
	{
		USanctuaryCompanionAviationPlayerComponent AviComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		AviComp.OnAviationStarted.AddUFunction(this, n"OnPlayerAviating");
	}

	UFUNCTION()
	private void OnPlayerAviating(AHazePlayerCharacter Player)
	{
		Reset();
	}

	private void Reset()
	{
		if (!bCrunched)
			return;
		bReturnPlatform = true;
		SetActorTickEnabled(true);
	}
};