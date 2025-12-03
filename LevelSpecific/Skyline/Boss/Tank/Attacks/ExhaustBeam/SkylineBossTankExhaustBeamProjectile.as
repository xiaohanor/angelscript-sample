event void FSkylineBossTankExhaustBeamProjectileSignature();

class ASkylineBossTankExhaustBeamProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(EditDefaultsOnly)
	float Speed = 15000.0;

	UPROPERTY(EditDefaultsOnly)
	float ExpireTime = 8.0;

	float DistanceMoved = 0.0;

	TArray<AGravityBikeFree> Bikes;

	UPROPERTY()
	FSkylineBossTankExhaustBeamProjectileSignature OnMovedDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Timer::SetTimer(this, n"Expire", ExpireTime);

		Bikes.Add(GravityBikeFree::GetGravityBike(Game::Mio));
		Bikes.Add(GravityBikeFree::GetGravityBike(Game::Zoe));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float MoveDistance = Speed * DeltaSeconds;

		if (DistanceMoved < (Collision.SphereRadius * 8.0))
		{
			DistanceMoved += MoveDistance;

			if (DistanceMoved >= (Collision.SphereRadius * 8.0))
				OnMovedDistance.Broadcast();
		}

		FVector DeltaMove = ActorForwardVector * MoveDistance;
		Move(DeltaMove);

		for (auto Bike : Bikes)
		{
			if (Bike.MoveComp.HasGroundContact())
			{
				FVector ToBike = Bike.ActorLocation - ActorLocation;
				float Distance = ToBike.Size();
				if (Distance < Collision.SphereRadius)
					Bike.GetDriver().DamagePlayerHealth(0.5);
			}
		}
	}

	void Move(FVector DeltaMove)
	{
		ActorLocation += DeltaMove;
	}

	UFUNCTION()
	void Expire()
	{
		DestroyActor();
	}
};