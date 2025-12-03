class ASplitTraversalFloatingPlatformTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TurretRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightPivotComp;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalDraggableFloatingPlatform FloatingPlatform;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalBranchLever Lever;

	UPROPERTY()
	FHazeTimeLike TurretRevealTimeLike;
	default TurretRevealTimeLike.UseSmoothCurveZeroToOne();
	default TurretRevealTimeLike.Duration = 1.0;

	bool bActive = false;
	bool bPlayerDetected = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true, true);

		for (auto AttachedActor : AttachedActors)
		{
			auto AttachedLaser = Cast<ASplitTraversalFloatingPlatformLaser>(AttachedActor);

			if (AttachedLaser != nullptr)
			{
				AttachedLaser.OnPlayerDetected.AddUFunction(this, n"HandlePlayerDetected");
			}

			auto AttachedRotator = Cast<AKineticRotatingActor>(AttachedActor);

			if (AttachedRotator != nullptr)
			{
				Lever.OnActivated.AddUFunction(AttachedRotator, n"PausePlatform");
			}

			auto AttachedMover = Cast<AKineticMovingActor>(AttachedActor);

			if (AttachedMover != nullptr)
			{
				Lever.OnActivated.AddUFunction(AttachedMover, n"PausePlatform");
			}
		}
		
		Lever.OnReachedEnd.AddUFunction(this, n"Deactivate");

		TurretRevealTimeLike.BindUpdate(this, n"TurretRevealTimeLikeUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bPlayerDetected)
		{
			TurretRoot.SetWorldRotation((Game::Mio.ActorCenterLocation - TurretRoot.WorldLocation).Rotation());
		}
	}

	UFUNCTION()
	void Activate()
	{
		bActive = true;

		TurretRevealTimeLike.Play();
		BP_Activate();

		auto HealthComp = UPlayerHealthComponent::GetOrCreate(Game::Mio);
		HealthComp.OnStartDying.AddUFunction(this, n"HandlePlayerDeath");

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true, true);

		
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION()
	void Deactivate()
	{
		bActive = false;

		TurretRevealTimeLike.Reverse();
		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivate(){}

	UFUNCTION()
	private void TurretRevealTimeLikeUpdate(float CurrentValue)
	{
		TurretRoot.SetRelativeLocation(FVector::ForwardVector * Math::Lerp(-500.0, 0.0, CurrentValue));
		LeftPivotComp.SetRelativeRotation(FRotator(0.0, CurrentValue * 160.0, 0.0));
		RightPivotComp.SetRelativeRotation(FRotator(0.0, CurrentValue * -160.0, 0.0));
	}

	UFUNCTION()
	private void HandlePlayerDetected()
	{
		if (bPlayerDetected)
			return;

		bPlayerDetected = true;
		
		Timer::SetTimer(this, n"Shoot", 0.1, true);
		//Timer::SetTimer(this, n"KillPlayer", 0.7);
	}

	UFUNCTION()
	private void Shoot()
	{
		BP_Shoot(ActorLocation, Game::Mio.ActorCenterLocation, (Game::Mio.ActorLocation - ActorLocation).GetSafeNormal());
		Game::Mio.DamagePlayerHealth(0.2);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Shoot(FVector StartLocation, FVector EndLocation, FVector ForwardVector) {}

	UFUNCTION()
	private void HandlePlayerDeath()
	{	
		Timer::ClearTimer(this, n"Shoot");
		Timer::SetTimer(this, n"ReenableTurret", 2.0);
	}

	UFUNCTION()
	private void ReenableTurret()
	{
		bPlayerDetected = false;
	}

	UFUNCTION(BlueprintCallable)
	void SpawnMuzzleFlashVFX(UNiagaraSystem NiagaraSystem, FVector Location, FVector Direction)
	{
		UNiagaraComponent MuzzleFlashNiagara = Niagara::SpawnOneShotNiagaraSystemAttached(NiagaraSystem, Root);
		
		if(MuzzleFlashNiagara == nullptr)
			return;

		MuzzleFlashNiagara.SetWorldTransform(FTransform(FQuat::MakeFromX(Direction), Location));
	}

	UFUNCTION(BlueprintCallable)
	void SpawnBulletImpactVFX(UNiagaraSystem NiagaraSystem, FVector ImpactPoint, FVector ImpactNormal)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraSystem, ImpactPoint, FRotator::MakeFromX(ImpactNormal));
	}

	UFUNCTION(BlueprintCallable)
	void SpawnBulletTrailVFX(UNiagaraSystem NiagaraSystem, FVector Start, FVector End, float Time = 0.1)
	{
		UNiagaraComponent TrailComp = Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraSystem, Start, FRotator::ZeroRotator);

		if(TrailComp == nullptr)
			return;

		TrailComp.SetFloatParameter(n"Time", Time);
		TrailComp.SetFloatParameter(n"BeamWidth", 1);
		TrailComp.SetVectorParameter(n"Start", Start);
		TrailComp.SetVectorParameter(n"End", End);
	}
};