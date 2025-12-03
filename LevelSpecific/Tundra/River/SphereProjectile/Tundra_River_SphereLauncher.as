event void FOnSphereLaunched();
class ATundra_River_SphereLauncher : AHazeActor
{
	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_River_SphereLauncher_Projectile> ProjectileList;
	UPROPERTY(EditInstanceOnly)
	float WaterHeight = 1000;
	int SpawnIndex = 0;
	ATundra_River_SphereLauncher_Projectile CurrentProjectile;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpawnLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Vfx;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraPlayerOtterSonarBlastTargetable InteractionComp;
	default InteractionComp.bIsImmediateTrigger = true;
	default InteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	default InteractionComp.ActionShape.BoxExtents = FVector(450, 450, 450);
	default InteractionComp.RelativeLocation = FVector(0,0,250);
	default InteractionComp.MovementSettings.Type = EMoveToType::NoMovement;

	UPROPERTY()
	FOnSphereLaunched OnSphereLaunched;

	UPROPERTY(EditInstanceOnly)
	bool bActive = true;

	UPROPERTY(EditInstanceOnly)
	bool bDeactivateAfterSpawn = false;

	UPROPERTY(EditInstanceOnly)
	bool bInteractionBlocked = false;

	bool bSpawnNewBallWhenReady = false;

	bool bHasSphere = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Vfx.Activate();	
		UpdateInteraction();
		if(bActive)
		{
			Timer::SetTimer(this, n"SpawnProjectile", 0.2, false, 0, 0);
		}

		InteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleInteraction");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bSpawnNewBallWhenReady)
		{
			if(!CurrentProjectile.bProjectileActive)
			{
				bSpawnNewBallWhenReady = false;
				SpawnProjectile();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetInteractionBlocked(bool bInInteractionBlocked)
	{
		bInteractionBlocked = bInInteractionBlocked;
		UpdateInteraction();
	}

	UFUNCTION()
	void ActivateSphereLauncher(bool bSpawnProjectileInstantly)
	{
		if(!bActive)
		{
			bActive = true;
			if (bSpawnProjectileInstantly)
				SpawnProjectileInstantly();
			else
				SpawnProjectile();
		}
	}

	UFUNCTION()
	void DeactivateSphereLauncher()
	{
		if(bActive)
		{
			bActive = false;
			UpdateInteraction();
			if(CurrentProjectile != nullptr)
			{
				CurrentProjectile.Disable();
			}
		}
	}

	UFUNCTION()
	void SpawnProjectileInstantly()
	{
		CurrentProjectile = ProjectileList[SpawnIndex].Spawn(SpawnLocation.GetWorldLocation(),WaterHeight, true);
		
		if(ProjectileList.IsValidIndex(SpawnIndex+1))
		{
			SpawnIndex++;
		}
		else
		{
			SpawnIndex = 0;
		}

		HandleProjectileFinishedSpawning();
	}

	UFUNCTION()
	void SpawnProjectile()
	{
		CurrentProjectile = ProjectileList[SpawnIndex].Spawn(SpawnLocation.GetWorldLocation(),WaterHeight, false);
		CurrentProjectile.SpawnFinishedEvent.AddUFunction(this, n"HandleProjectileFinishedSpawning");
		
		if(ProjectileList.IsValidIndex(SpawnIndex+1))
		{
			SpawnIndex++;
		}
		else
		{
			SpawnIndex = 0;
		}
	}

	UFUNCTION(BlueprintCallable)
	void DebugLaunchProjectile()
	{
		LaunchProjectile();
	}

	UFUNCTION()
	private void HandleInteraction(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		LaunchProjectile();
	}

	private void LaunchProjectile()
	{
		bHasSphere = false;
		UpdateInteraction();
		CurrentProjectile.StartMoving();
		//CurrentProjectile = nullptr;
		OnSphereLaunched.Broadcast();

		if (bDeactivateAfterSpawn)
			DeactivateSphereLauncher();
		else
		{
			if(bActive)
			{
				bSpawnNewBallWhenReady = true;
				//SpawnProjectile();
			}
		}
	}

	UFUNCTION()
	private void HandleProjectileFinishedSpawning()
	{
		CurrentProjectile.SpawnFinishedEvent.Unbind(this, n"HandleProjectileFinishedSpawning");
		bHasSphere = true;
		UpdateInteraction();
	}

	UFUNCTION()
	void SetSphereInteractionComponentEnabled(bool bEnable)
	{
		bInteractionBlocked = !bEnable;
		UpdateInteraction();
	}

	UFUNCTION()
	private void UpdateInteraction()
	{
		if(bActive && !bInteractionBlocked && bHasSphere)
		{
			InteractionComp.Enable(this);
		}
		else
		{
			InteractionComp.Disable(this);
		}
	}

	void SetLauncherVFXActive(bool bVFXActive)
	{
		if (bVFXActive)
			Vfx.Activate();
		else
			Vfx.Deactivate();
	}
};