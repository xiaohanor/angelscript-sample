class ASummitRollingGemLog : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RollRotateRoot;

	UPROPERTY(DefaultComponent, Attach = RollRotateRoot)
	USceneComponent NewMeshRoot;

	default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DustParticles;

	UPROPERTY(DefaultComponent)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerComp;

	UPROPERTY()
	UNiagaraSystem SpawnEffect;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LoopingCameraShake;
	ASplineActor Spline;

	UHazeSplineComponent SplineComp;
	float CurrentDistance = 0.0;
	float Speed = 1600.0;

	FVector StartScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SplineComp = Spline.Spline;
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
		StartScale = RollRotateRoot.RelativeScale3D;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffect, ActorLocation);
		OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
		DeathComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		MoveIntoPlayerComp.OnImpactPlayer.AddUFunction(this, n"OnMovedIntoPlayer");
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			if (PlayerIsRolling(Player))
				return;
			
			RollOverPlayer(Player);
		}
	}

	UFUNCTION()
	private void OnMovedIntoPlayer(AHazePlayerCharacter Player)
	{
		if (PlayerIsRolling(Player))
		{
			DestroyCrystal();
			return;
		}
		
		RollOverPlayer(Player);
	}

	private void RollOverPlayer(AHazePlayerCharacter Player)
	{
		if (Player.IsPlayerInvulnerable())
			return;
		
		FVector Direction = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		Player.KillPlayer(FPlayerDeathDamageParams(Direction, 15.0));
	}

	private bool PlayerIsRolling(AHazePlayerCharacter Player) const
	{
		if(Player == nullptr)
			return false;

		auto RollComp = UTeenDragonRollComponent::Get(Player);
		if(RollComp == nullptr)
			return false;

		if(!RollComp.IsRolling())
			return false;

		return true;
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		FOnSummitGemDestroyedParams DestroyParams;
		DestroyParams.Location = ActorLocation;
		DestroyParams.Rotation = ActorRotation;
		DestroyParams.Scale = 1.5;
		USummitGemDestructionEffectHandler::Trigger_DestroyRegularGem(this, DestroyParams);
		DeathComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		Game::Mio.PlayWorldCameraShake(LoopingCameraShake, this, ActorLocation, 2500.0, 10000.0, Scale = 1.0);
		Game::Zoe.PlayWorldCameraShake(LoopingCameraShake, this, ActorLocation, 2500.0, 10000.0, Scale = 1.0);
		RollRotateRoot.AddLocalRotation(FRotator(180, 0.0, 0.0) * DeltaSeconds);

		RollRotateRoot.RelativeScale3D = Math::VInterpConstantTo(RollRotateRoot.RelativeScale3D, StartScale, DeltaSeconds, StartScale.Size() * 2.5);

		CurrentDistance += Speed * DeltaSeconds;
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
		ActorLocation += FVector::UpVector * 200.0;

		if (CurrentDistance >= SplineComp.SplineLength)
		{
			Game::Mio.StopCameraShakeByInstigator(this);
			Game::Zoe.StopCameraShakeByInstigator(this);
			USummitRollingObjectEventHandler::Trigger_OnDespawn(this);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffect, ActorLocation);
			DestroyActor();
		}
	}
}