
UCLASS(Abstract)
class AScifiPlayerGravityGrenadeWeapon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
}

UCLASS(Abstract)
class AScifiPlayerGravityGrenadeWeaponProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;
	default Collision.SetCollisionProfileName(n"IgnorePlayerCharacter");
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent GravityGrenadeMesh;
	default GravityGrenadeMesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY()
	ECollisionChannel TraceChannel;

	float ActivationTime = 0;

	UScifiGravityGrenadeTargetableComponent LaunchTarget;
	
	UScifiPlayerGravityGrenadeSettings Settings;
	FVector MoveDirection;
	float CurrentMovementSpeed = 0;
	float UpSpeed = 0.0;
	float UpOffset = 0.0;

	FScifiPlayerGravityGrenadeWeaponImpact MovementImpact;

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		MoveDirection = FVector::ZeroVector;
		LaunchTarget = nullptr;
		CurrentMovementSpeed = 0;
		MovementImpact = FScifiPlayerGravityGrenadeWeaponImpact();
	}

	void CalculateUpSpeed()
	{
		if(LaunchTarget == nullptr)
		{
			UpSpeed = Settings.InitialUpVelocityNoTarget;
			UpOffset = 0;
		}

		else
		{
			float DistanceToTravel = (LaunchTarget.GetOwner().GetActorLocation() - GetActorLocation()).Size();
			Print("DistanceToTravel " + DistanceToTravel, 3.0);
			float TimeToTravel = DistanceToTravel / CurrentMovementSpeed;
			UpSpeed = Settings.Gravity * (TimeToTravel/2);
			UpOffset = 0;

		}
	}

	void MoveControl(float DeltaTime)
	{
		CurrentMovementSpeed = Settings.Speed;
		UpOffset += UpSpeed * DeltaTime;
		UpSpeed -= Settings.Gravity * DeltaTime;

		FVector MeshLocation = Root.GetWorldLocation() + FVector(0,0,UpOffset);
		GravityGrenadeMesh.SetWorldLocation(MeshLocation);

		// Update the move direction if we have a target
		MoveDirection = GetWantedMovementDirection();

		FVector CurrentLocation = GetActorLocation();
		FVector Velocity = MoveDirection * CurrentMovementSpeed;
		FVector PendingLocation = CurrentLocation + (Velocity * DeltaTime);
		FVector Delta = PendingLocation - CurrentLocation;

		// Experimenting with trace channel instead of collision profile.
		auto TraceSettings = Trace::InitChannel(TraceChannel);
		TraceSettings.UseComponentShape(Collision);
		TraceSettings.IgnoreActor(this, true);
		TraceSettings.IgnoreActor(Game::Zoe);

		bool bHasBlockingHit = false;
		FHitResult TraceImpact;

		if(LaunchTarget == nullptr)
		{
			TraceImpact = TraceSettings.QueryTraceSingle(CurrentLocation, PendingLocation);
			bHasBlockingHit = TraceImpact.bBlockingHit;
		}
		// If we have a target, we are guaranteed to hit that
		else
		{
			auto TraceImpacts = TraceSettings.QueryTraceMulti(CurrentLocation, PendingLocation);
			for(auto Impact : TraceImpacts)
			{
				if(Impact.Actor != LaunchTarget.Owner)
					continue;

				bHasBlockingHit = Impact.bBlockingHit;
				TraceImpact = Impact;
			}
		}
		
		if(!bHasBlockingHit)
		{
			SetActorLocation(PendingLocation);
		}
		else
		{
			SetActorLocation(PendingLocation);
			MovementImpact = FScifiPlayerGravityGrenadeWeaponImpact(TraceImpact, LaunchTarget);		
		}
	}

	void MoveRemote(float DeltaTime)
	{
		CurrentMovementSpeed = Settings.Speed;

		// Update the move direction if we have a target
		MoveDirection = GetWantedMovementDirection();

		FVector CurrentLocation = GetActorLocation();
		FVector Velocity = MoveDirection * CurrentMovementSpeed;
		FVector PendingLocation = CurrentLocation + (Velocity * DeltaTime);
		//FVector Delta = PendingLocation - CurrentLocation;
		SetActorLocation(PendingLocation);
	}

	bool HasImpact() const
	{
		return MovementImpact.bIsValid;
	}
	
	FVector GetWantedMovementDirection() const
	{
		if(LaunchTarget != nullptr)
			return (LaunchTarget.GetWorldLocation() - GetActorLocation()).GetSafeNormal();
		else
			return MoveDirection;
	}

	float GetMaxLifeTime() const
	{
		return Settings.ProjectileMaxLifeTime;
	}
}
