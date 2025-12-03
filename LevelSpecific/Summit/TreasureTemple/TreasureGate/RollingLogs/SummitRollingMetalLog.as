asset NightQueenMetalLogMeltingSettings of UNightQueenMetalMeltingSettings
{
	MeltingSpeed = 8.0;
	
	Health = 0.05;
}

class ASummitRollingMetalLog : ANightQueenMetal
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RollRotateRoot;

	UPROPERTY(DefaultComponent, Attach = RollRotateRoot)
	USceneComponent NewMeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDeathTriggerComponent DeathComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DustParticles;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DamageCollision;

	UPROPERTY()
	UNiagaraSystem SpawnEffect;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LoopingCameraShake;
	ASplineActor Spline;

	UHazeSplineComponent SplineComp;
	float CurrentDistance = 0.0;
	float Speed = 1600.0;

	UPROPERTY()
	FRotator StartRelativeRot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	FVector StartScale;

	bool bCanKill = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		//ApplyDefaultSettings(NightQueenMetalLogMeltingSettings);

		OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");

		SplineComp = Spline.Spline;
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);

		StartRelativeRot = MeshRoot.RelativeRotation;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffect, ActorLocation);

		StartScale = MeshRoot.RelativeScale3D;
		MeshRoot.RelativeScale3D = FVector(0.0001);

		DamageCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnDamageOverlap");

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Game::Mio.PlayWorldCameraShake(LoopingCameraShake, this, ActorLocation, 2500.0, 10000.0, Scale = 1.0);
		Game::Zoe.PlayWorldCameraShake(LoopingCameraShake, this, ActorLocation, 2500.0, 10000.0, Scale = 1.0);
		RollRotateRoot.AddLocalRotation(FRotator(180, 0.0, 0.0) * DeltaSeconds);

		MeshRoot.RelativeScale3D = Math::VInterpConstantTo(MeshRoot.RelativeScale3D, StartScale, DeltaSeconds, StartScale.Size() * 2.5);

		CurrentDistance += Speed * DeltaSeconds;
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
		ActorLocation += FVector::UpVector * 200.0;

		if (CurrentDistance >= SplineComp.SplineLength - 10.0)
		{
			Game::Mio.StopCameraShakeByInstigator(this);
			Game::Zoe.StopCameraShakeByInstigator(this);
			USummitRollingObjectEventHandler::Trigger_OnDespawn(this);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffect, ActorLocation);
			DestroyActor();
		}
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		bCanKill = true;
		DeathComp.EnableTrigger(this);
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		bCanKill = false;
		DeathComp.DisableTrigger(this);
	}

	UFUNCTION()
	void OnDamageOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		if (!bCanKill)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player.IsPlayerInvulnerable())
			return;

		Player.KillPlayer(FPlayerDeathDamageParams(ActorForwardVector * -1, 15.0), DeathEffect);

	}
	
}