UCLASS(Abstract)
class ASummitEggBeastProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LandedEffect;
	default LandedEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpikeRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	UPROPERTY()
	UNiagaraSystem ShootEffect;

	UPROPERTY()
	UNiagaraSystem ExplodeEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffect")
	TSubclassOf<UDeathEffect> DeathEffect;

	FVector StartLocation;
	FVector TargetLocation;
	FVector ControlPoint;

	FVector StartScale;

	float MoveDuration;
	float StartTime;
	float SquaredRadius;
	AActor IgnoreActor;

	bool bDestroyWhenReachEnd = false;
	bool bHasReachedEnd = false;

	FHazeRuntimeSpline TrajectorySpline;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector Direction = TargetLocation - StartLocation;
		float Length = Direction.Size();
		Direction = Direction.GetSafeNormal();

		TArray<FVector> DesiredSplinePoints;
		DesiredSplinePoints.Add(StartLocation);
		DesiredSplinePoints.Add(StartLocation + ActorUpVector * 250);
		if (Length > 7000)
		{
			DesiredSplinePoints.Add(StartLocation + (Direction * Length * 0.4) + FVector::UpVector * 1500);
			DesiredSplinePoints.Add(StartLocation + (Direction * Length * 0.6) + FVector::UpVector * 1400);
			DesiredSplinePoints.Add(StartLocation + (Direction * Length * 0.8) + FVector::UpVector * 1000);
			DesiredSplinePoints.Add(StartLocation + (Direction * Length * 0.9) + FVector::UpVector * 600);
			DesiredSplinePoints.Add(TargetLocation);
		}
		else
		{
			MoveDuration *= 0.85;
			DesiredSplinePoints.Add(StartLocation + (Direction * Length * 0.2) + FVector::UpVector * 100);
			DesiredSplinePoints.Add(StartLocation + (Direction * Length * 0.4) + FVector::UpVector * 300);
			DesiredSplinePoints.Add(TargetLocation);
		}

		TrajectorySpline.Points = DesiredSplinePoints;

		StartScale = Mesh.RelativeScale3D;
		Mesh.RelativeScale3D = FVector(0.05);

		SquaredRadius = SphereComp.SphereRadius * SphereComp.SphereRadius;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ShootEffect, ActorLocation);
		SpikeRoot.SetHiddenInGame(true, true);
		SphereComp.OnComponentBeginOverlap.AddUFunction(this, n"OnSphereOverlap");
	}

	void Initialize(FVector InStartLocation, FVector EndLocation, bool bInDestroyWhenReachEnd, float InMoveDuration)
	{
		StartLocation = InStartLocation;
		TargetLocation = EndLocation;
		MoveDuration = InMoveDuration;
		bDestroyWhenReachEnd = bInDestroyWhenReachEnd;
		StartTime = Time::GameTimeSeconds;
		IgnoreActor = this;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void OnSphereOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                             const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
 			Player.KillPlayer(FPlayerDeathDamageParams(ActorUpVector, 1.0), DeathEffect);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ActiveDuration = Time::GetGameTimeSince(StartTime);
		float MoveAlpha = ActiveDuration / MoveDuration;
		FVector NewLocation;
		FRotator NewRotation;
		TrajectorySpline.GetLocationAndRotation(MoveAlpha, NewLocation, NewRotation);
		SetActorLocationAndRotation(NewLocation, FRotator::MakeFromZX(NewRotation.ForwardVector, NewRotation.UpVector));

		Mesh.RelativeScale3D = Math::VInterpTo(Mesh.RelativeScale3D, StartScale, DeltaSeconds, 1.4);

		if (!bHasReachedEnd)
		{
			Mesh.AddLocalRotation(FRotator(0.0, Math::RandRange(200, 300), 0.0) * DeltaSeconds);
		}

		if (ActiveDuration >= MoveDuration)
		{
			if (!bHasReachedEnd)
			{
				bHasReachedEnd = true;
				for (auto Player : Game::Players)
				{
					Player.PlayWorldCameraShake(ImpactCameraShake, this, ActorLocation, 1000, 5000);
				}
				
				ForceFeedback::PlayWorldForceFeedback(ForceFeedback::Default_Heavy_Short, ActorLocation, true,this, 1000, 5000);

				BPOnImpact();
				LandedEffect.Activate();
				float RandYaw = Math::RandRange(0.0, 359.0);
				SpikeRoot.SetWorldRotation(FRotator(0,RandYaw,0));
				SpikeRoot.SetHiddenInGame(false, true);
				Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplodeEffect, ActorLocation);
				USummitEggBeastProjectileEventHandler::Trigger_OnProjectileImpact(this);
			}
			if (!bDestroyWhenReachEnd)
			{
				auto TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
				TraceSettings.UseSphereShape(SphereComp.SphereRadius);
				auto Overlaps = TraceSettings.QueryOverlaps(ActorLocation);
				bool bShouldExplode = true;
				for (auto Overlap : Overlaps)
				{
					auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
					if (Player != nullptr)
					{
						Player.KillPlayer(FPlayerDeathDamageParams(ActorUpVector, 1.0), DeathEffect);
					}
					else if (Overlap.Component.Mobility == EComponentMobility::Static)
					{
						bShouldExplode = false;
					}
				}
				if (Overlaps.Num() == 0 || bShouldExplode)
				{
					USummitEggBeastProjectileEventHandler::Trigger_OnProjectileImpact(this);
					Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplodeEffect, ActorLocation);
					DestroyActor();
				}
			}
			else
			{
				USummitEggBeastProjectileEventHandler::Trigger_OnProjectileImpact(this);
				Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplodeEffect, ActorLocation);
				DestroyActor();
			}
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BPOnImpact() {}
};