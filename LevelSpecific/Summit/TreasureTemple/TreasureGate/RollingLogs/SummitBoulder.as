class ASummitBoulder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeMovablePlayerTriggerComponent OverlappedComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DustParticles;

	UPROPERTY()
	UNiagaraSystem SpawnEffect;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LoopingCameraShake;
	ASplineActor Spline;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UHazeSplineComponent SplineComp;
	float CurrentDistance = 0.0;
	float Speed = 2000.0;

	UPROPERTY()
	FRotator StartRelativeRot;

	FVector StartScale;
	FVector MoveDirection;

	UCameraShakeBase CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlappedComponent.OnPlayerEnter.AddUFunction(this,n"PlayerOverlap");

		SplineComp = Spline.Spline;
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
		StartRelativeRot = MeshRoot.RelativeRotation;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffect, ActorLocation);

		StartScale = MeshRoot.RelativeScale3D;
		MeshRoot.RelativeScale3D = FVector(0.0001);
	}

	UFUNCTION()
	private void PlayerOverlap(AHazePlayerCharacter Player)
	{
		if (Player.IsPlayerInvulnerable())
			return;
		
		Player.KillPlayer(FPlayerDeathDamageParams(MoveDirection, 15.0), DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Game::Mio.PlayWorldCameraShake(LoopingCameraShake, this, ActorLocation, 2700.0, 10000.0, Scale = 1.0);
		Game::Zoe.PlayWorldCameraShake(LoopingCameraShake, this, ActorLocation, 2700.0, 10000.0, Scale = 1.0);

		RotateRoot.AddLocalRotation(FRotator(200.0 * DeltaSeconds, 0.0, 0.0));
		MeshRoot.RelativeScale3D = Math::VInterpConstantTo(MeshRoot.RelativeScale3D, StartScale, DeltaSeconds, StartScale.Size() * 2.5);

		CurrentDistance += Speed * DeltaSeconds;
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
		ActorLocation -= FVector::UpVector * 80.0;
		MoveDirection = SplineComp.GetWorldRotationAtSplineDistance(CurrentDistance).Vector();

		if (CurrentDistance > SplineComp.SplineLength)
		{
			Game::Mio.StopCameraShakeByInstigator(this);
			Game::Zoe.StopCameraShakeByInstigator(this);
			USummitRollingObjectEventHandler::Trigger_OnDespawn(this);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffect, ActorLocation);
			DestroyActor();
		}
	}
}