event void FWhirlwindStartEvent(float Delay);
event void FWhirlwindEvent();

class ATundraBossWhirlwindActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraBossWhirlwindForceComponent WhirlwindForceComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent WhirlwindMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent SmallWhirlwindSpawnLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ForeshadowVFX;
	default ForeshadowVFX.bAutoActivate = false;
	default ForeshadowVFX.SetFloatParameter(n"Lifetime", 3);

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent KillCollision;
	default KillCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CameraBlockMesh;
	default CameraBlockMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem MeshHitPlayerVFX;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> WhirlwindCamShake;

	UPROPERTY()
	FWhirlwindStartEvent OnWhirlwindStart;
	UPROPERTY()
	FWhirlwindEvent OnWhirlwindStop;

	UPROPERTY()
	TSubclassOf<UDeathEffect> WhirlwindDeathEffect;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundraBossSmallWhirlwindActor> SmallWhirlwinds;

	UPROPERTY(EditInstanceOnly)
	ATundraBoss Boss;

	FHazeTimeLike FadeWhirlwindMaterialTimelike;
	default FadeWhirlwindMaterialTimelike.Duration = 3;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	float CurrentSmallWhirlwindSpawnDelay = 0;
	float SpawnTimer = 0;
	float SpawnInterval = 0.35;
	bool bShouldSpawnSmallWhirlwinds = false;
	bool bAboutToActivate = false;
	bool bActivateWithForeshadow = false;
	int SmallWhirlwindIndex = 0;
	float WhirlwindRotationSpeed = -55;
	TArray<float> RandomSpawnLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		SetActorControlSide(Game::Zoe);
		
		FadeWhirlwindMaterialTimelike.BindUpdate(this, n"FadeWhirlwindMaterialTimelikeUpdate");
		FadeWhirlwindMaterialTimelike.BindFinished(this, n"FadeWhirlwindMaterialTimelikeFinished");
		KillCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnKillCollisionOverlap");

		if(HasControl())
		{
			FVector Loc = SmallWhirlwindSpawnLocation.WorldLocation;
			for(auto SmallWhirlwind : SmallWhirlwinds)
			{
				RandomSpawnLoc.Add(Math::RandRange(Loc.Y - 2500, Loc.Y - 500));
			}

			CrumbSyncRandomSpawnLoc(RandomSpawnLoc);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSyncRandomSpawnLoc(TArray<float> NewRandomSpawnLoc)
	{
		if(!HasControl())
		{
			RandomSpawnLoc = NewRandomSpawnLoc;
		}
	}

	UFUNCTION()
	private void FadeWhirlwindMaterialTimelikeFinished()
	{
		if(FadeWhirlwindMaterialTimelike.IsReversed())
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void FadeWhirlwindMaterialTimelikeUpdate(float CurrentValue)
	{
		WhirlwindMesh.SetScalarParameterValueOnMaterialIndex(0, n"Opacity", Math::Lerp(0, 1, CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		MeshRoot.AddLocalRotation(FRotator(0, WhirlwindRotationSpeed * DeltaSeconds, 0));

		if(bShouldSpawnSmallWhirlwinds)
		{
			SpawnTimer += DeltaSeconds;
			if(SpawnTimer >= SpawnInterval)
			{
				SpawnTimer = 0;
				SmallWhirlwinds[SmallWhirlwindIndex].SpawnSmallWhirlwind(RandomSpawnLoc[SmallWhirlwindIndex]);
				SmallWhirlwindIndex++;

				if(!SmallWhirlwinds.IsValidIndex(SmallWhirlwindIndex))
					SmallWhirlwindIndex = 0;
			}
		}
	}

	bool PlayerInsideKillCollision(AHazePlayerCharacter Player)
	{
		float X = Math::Abs(Player.ActorLocation.X - KillCollision.WorldLocation.X);
		float Y = Math::Abs(Player.ActorLocation.Y - KillCollision.WorldLocation.Y);

		if(X < KillCollision.BoundingBoxExtents.X && Y < KillCollision.BoundingBoxExtents.Y)
			return true;
		else
			return false;

	}

	UFUNCTION()
	void ActivateWhirlwind(float SpawnSmallWhirlwindsDelay, bool bWithForeshadow = false)
	{
		CurrentSmallWhirlwindSpawnDelay = SpawnSmallWhirlwindsDelay;
		UTundraBoss_EffectHandler::Trigger_OnWhirlwindStart(Boss);
		bActivateWithForeshadow = bWithForeshadow;
		
		if(bActivateWithForeshadow)
		{
			ForeshadowVFX.Activate(true);
			Timer::SetTimer(this, n"ActivateWhirlwindInternal", 3);
		}
		else
		{
			ActivateWhirlwindInternal();
		}
	}

	UFUNCTION()
	private void ActivateWhirlwindInternal()
	{
		SmallWhirlwindIndex = 0;
		SetActorTickEnabled(true);
		Timer::SetTimer(this, n"StartSpawningSmallWhirlwinds", CurrentSmallWhirlwindSpawnDelay);
		ActivateKillCollision();
		SetActorHiddenInGame(false);
		FadeWhirlwindMaterialTimelike.PlayFromStart();
		bAboutToActivate = true;
		OnWhirlwindStart.Broadcast(CurrentSmallWhirlwindSpawnDelay);
		SetCameraBlockEnabled(true);
		ForeshadowVFX.DeactivateImmediately();
		UTundraBossWhirlwindActor_EffectHandler::Trigger_OnWhirlwindStarted(this);

		for(auto Player : Game::GetPlayers())
			Player.PlayCameraShake(WhirlwindCamShake, this);
	}

	UFUNCTION()
	private void ActivateKillCollision()
	{
		KillCollision.CollisionEnabled = ECollisionEnabled::QueryOnly;
		bAboutToActivate = false;
	}

	void DeactivateKillCollision()
	{
		KillCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
		OnWhirlwindStop.Broadcast();
	}

	UFUNCTION()
	void StartSpawningSmallWhirlwinds()
	{
		bShouldSpawnSmallWhirlwinds = true;
	}

	void StopSpawningSmallWhirlwinds()
	{
		bShouldSpawnSmallWhirlwinds = false;
	}

	UFUNCTION()
	void DeactivateWhirlwind()
	{
		FadeWhirlwindMaterialTimelike.ReverseFromEnd();
		UTundraBossWhirlwindActor_EffectHandler::Trigger_OnWhirlwindStopped(this);
		
		FTudnraBossWhirlwindStopData Data;
		// If it was activated with foreshadow, we know that it's in the 2nd part of P3. Meaning we should play the hint.
		Data.bShouldPlaySphereHint = !bActivateWithForeshadow;
		UTundraBoss_EffectHandler::Trigger_OnWhirlwindStop(Boss, Data);
		bShouldSpawnSmallWhirlwinds = false;

		for(auto Player : Game::GetPlayers())
			Player.StopCameraShakeByInstigator(this, false);

		for(auto SmallWhirlwind : SmallWhirlwinds)
			SmallWhirlwind.DespawnSmallWhirlwind();

		SetCameraBlockEnabled(false);
		DeactivateKillCollision();
	}

	void SetCameraBlockEnabled(bool bEnabled)
	{
		ECollisionEnabled Collision = bEnabled ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision;
		CameraBlockMesh.CollisionEnabled = Collision;
	}

	UFUNCTION()
	private void OnKillCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                    UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                    bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(!Player.HasControl())
			return;

		Player.KillPlayer();
	}

	UFUNCTION(CallInEditor)
	void FillSmallWhirlwindsWithSelectedActors()
	{
		SmallWhirlwinds.Empty();
		TArray<AActor> Actors = Editor::SelectedActors;

		for(auto Actor : Actors)
		{
			ATundraBossSmallWhirlwindActor SmallWhirlwind = Cast<ATundraBossSmallWhirlwindActor>(Actor);
			if(SmallWhirlwind == nullptr)
				continue;

			SmallWhirlwinds.Add(SmallWhirlwind);
		}
	}
};