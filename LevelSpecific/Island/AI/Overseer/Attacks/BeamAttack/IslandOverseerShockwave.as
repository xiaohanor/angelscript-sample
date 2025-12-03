UCLASS(Abstract)
class AIslandOverseerShockwave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DamageCollision;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshContainer;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USceneComponent StartFxContainer;

	UPROPERTY(DefaultComponent)
	USceneComponent RollFxContainer;

	UPROPERTY()
	FHazeTimeLike DropTimeLike;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	AAIIslandOverseer Overseer;
	UHazeSplineComponent Spline;
	float Distance;
	float ActiveDuration;
	float StartOffset;
	bool bStarted;
	bool bLanded;
	float Speed = 1300;
	float AccelerationDuration = 2;
	FHazeAcceleratedFloat AccSpeed;
	FVector PreviousLocation;
	TArray<AHazePlayerCharacter> HitPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AIslandOverseerTowardsChaseMoveSplineContainer Container = TListedActors<AIslandOverseerTowardsChaseMoveSplineContainer>()[0];
		TArray<AActor> Actors;
		Container.GetAttachedActors(Actors);
		Spline = Cast<ASplineActor>(Actors[0]).Spline;
		Distance = Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		StartOffset = ActorLocation.Z - Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation).Z;
		Overseer = TListedActors<AAIIslandOverseer>().GetSingle();
		AccSpeed.SnapTo(Speed / 2);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bStarted)
		{
			SetActorTickEnabled(false);
			return;
		}
		Move(DeltaSeconds);
	}

	void Start()
	{
		if(!HasControl())
			return;
		CrumbStart();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStart()
	{
		bStarted = true;
		SetActorTickEnabled(true);

		DropTimeLike.SetPlayRate(2);
		DropTimeLike.Play();

		TArray<UNiagaraComponent> Systems;
		StartFxContainer.GetChildrenComponentsByClass(UNiagaraComponent, true, Systems);
		for(UNiagaraComponent System : Systems)
			System.Activate();
	}

	private void StartRoll()
	{
		TArray<UNiagaraComponent> Systems;
		RollFxContainer.GetChildrenComponentsByClass(UNiagaraComponent, true, Systems);
		for(UNiagaraComponent System : Systems)
			System.Activate();
	}

	void Move(float DeltaSeconds)
	{
		AccSpeed.AccelerateTo(Speed, AccelerationDuration, DeltaSeconds);
		Distance += DeltaSeconds * AccSpeed.Value;

		if(Distance >= Spline.SplineLength)
			AddActorDisable(this);

		FVector NewLocation = Spline.GetWorldLocationAtSplineDistance(Distance);

		if(DropTimeLike.IsPlaying())
		{
			NewLocation.Z = NewLocation.Z + DropTimeLike.GetValue() * StartOffset;
		}
		else if(!bLanded)
		{
			bLanded = true;
			StartRoll();
		}

		SetActorLocation(NewLocation);

		FVector Dir = (Spline.GetWorldLocationAtSplineDistance(Distance+50) - Spline.GetWorldLocationAtSplineDistance(Distance)).GetSafeNormal();
		SetActorRotation(Dir.Rotation());

		MeshContainer.AddLocalRotation(FRotator(DeltaSeconds * -500, 0, 0));

		if(PreviousLocation == FVector::ZeroVector)
			PreviousLocation = DamageCollision.WorldTransform.Location;
		FVector Delta = PreviousLocation - DamageCollision.WorldTransform.Location;
		PreviousLocation = DamageCollision.WorldTransform.Location;

		if(Delta.IsNearlyZero())
			return;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;
			if(HitPlayers.Contains(Player))
				continue;
			if(Player.IsPlayerRespawning())
				continue;
			FHazeTraceSettings Trace = Trace::InitAgainstComponent(Player.CapsuleComponent);
			Trace.UseCapsuleShape(DamageCollision.CapsuleRadius, DamageCollision.CapsuleHalfHeight, DamageCollision.WorldRotation.Quaternion());
			FHitResult Hit = Trace.QueryTraceComponent(DamageCollision.WorldTransform.Location, DamageCollision.WorldTransform.Location - Delta);
			if (Hit.bBlockingHit)
			{
				Player.KillPlayer(DeathEffect = DeathEffect);
				HitPlayers.Add(Player);
			}
		}
	}
}