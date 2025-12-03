UCLASS(Abstract)
class ATundraPondBeastBait : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"NoCollision";

	UPROPERTY(EditAnywhere)
	float MaxLifeTime = 10.0;

	UPROPERTY()
	bool HasLanded;

	FVector Velocity = FVector::ZeroVector;
	float GravityAcceleration = 0.0;
	UHazeActorNetworkedSpawnPoolComponent SpawnPoolComponent;
	float TimeOfSpawn = -100.0;
	FVector OldLocation;
	
	UPROPERTY()
	bool bHitTrigger = false;
	
	ATundraPondBeastBaitGun Gun;

	void Initialize(FVector In_Velocity, float In_GravityAcceleration, UHazeActorNetworkedSpawnPoolComponent In_SpawnPoolComponent, ATundraPondBeastBaitGun In_Gun)
	{
		TimeOfSpawn = Time::GetGameTimeSeconds();
		Velocity = In_Velocity;
		GravityAcceleration = In_GravityAcceleration;
		SpawnPoolComponent = In_SpawnPoolComponent;
		OldLocation = Collision.WorldLocation;
		Gun = In_Gun;
		RemoveActorDisable(this);
	}

	UFUNCTION()
	void UnSpawn()
	{
		bHitTrigger = false;
		AddActorDisable(this);
		SpawnPoolComponent.UnSpawn(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bHitTrigger)
		{
			HandleLifetime();
			return;
		}

		Velocity -= FVector::UpVector * (GravityAcceleration * DeltaTime);
		ActorLocation += Velocity * DeltaTime;

		if(!HandleCollision())
			HandleLifetime();
	}

	bool HandleCollision()
	{
		FVector SphereLocation = Collision.WorldLocation;

		// Should not trace when origin and destination are the same -> this will cause an exception
		if(SphereLocation.Equals(OldLocation))
			return false;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseShape(FHazeTraceShape::MakeSphere(Collision.ScaledSphereRadius));
		Trace.IgnorePlayers();
		Trace.IgnoreActor(Gun);
		Trace.IgnoreActor(this);
		FHitResult Hit = Trace.QueryTraceSingle(OldLocation, SphereLocation);

		OldLocation = SphereLocation;

		if(!Hit.bBlockingHit)
			return false;

		if(Hit.Actor == nullptr)
			return false;

		if(Cast<ATundraPondBeastBaitTrigger>(Hit.Actor) != nullptr)
		{
			bHitTrigger = true;
			TriggerImpactEffect();
			Velocity = FVector::ZeroVector;
			return true;
		}

		TriggerImpactEffect();

		UnSpawn();
		return true;
	}

	void HandleLifetime()
	{
		if(Time::GetGameTimeSeconds() - TimeOfSpawn > MaxLifeTime)
		{
			UnSpawn();
		}
	}

	void TriggerImpactEffect()
	{
		FTundraPondBeastBaitOnImpactParameters Params;
		Params.BeastBaitProjectile = this;
		Params.ProjectileLocation = ActorLocation;
		UTundraPondBeastBaitEffectHandler::Trigger_OnImpact(this, Params);
	}
}