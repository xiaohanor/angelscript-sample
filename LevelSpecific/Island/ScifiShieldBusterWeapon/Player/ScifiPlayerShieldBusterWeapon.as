
UCLASS(Abstract)
class AScifiPlayerShieldBusterWeapon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditConst, Transient)
	EScifiPlayerShieldBusterHand AttachType;
}


UCLASS(Abstract)
class AScifiPlayerShieldBusterWeaponProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;
	default Collision.SetCollisionProfileName(n"IgnorePlayerCharacter");
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY()
	ECollisionChannel TraceChannel;

	float ActivationTime = 0;

	UScifiShieldBusterTargetableComponent LaunchTarget;
	
	UScifiPlayerShieldBusterSettings Settings;
	FVector MoveDirection;
	float CurrentMovementSpeed = 0;

	FScifiPlayerShieldBusterWeaponImpact MovementImpact;

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		MoveDirection = FVector::ZeroVector;
		LaunchTarget = nullptr;
		CurrentMovementSpeed = 0;
		MovementImpact = FScifiPlayerShieldBusterWeaponImpact();
	}

	void MoveControl(float DeltaTime)
	{
		const float MoveSpeedMax = Settings.SpeedMax;
		const float Acc = Settings.SpeedAcceleration * DeltaTime;
		CurrentMovementSpeed = Math::Min(CurrentMovementSpeed + Acc, MoveSpeedMax);
		
		// Update the move direction if we have a target
		MoveDirection = GetWantedMovementDirection();

		FVector CurrentLocation = GetActorLocation();
		FVector Velocity = MoveDirection * CurrentMovementSpeed;
		FVector PendingLocation = CurrentLocation + (Velocity * DeltaTime);
		FVector Delta = PendingLocation - CurrentLocation;

		// Experimenting with trace channel instead of collision profile.
		auto TraceSettings = Trace::InitChannel(TraceChannel);
		TraceSettings.UseComponentShape(Collision);

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
			MovementImpact = FScifiPlayerShieldBusterWeaponImpact(TraceImpact, LaunchTarget);		
		}
	}

	void MoveRemote(float DeltaTime)
	{
		const float MoveSpeedMax = Settings.SpeedMax;
		const float Acc = Settings.SpeedAcceleration * DeltaTime;
		CurrentMovementSpeed = Math::Min(CurrentMovementSpeed + Acc, MoveSpeedMax);

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
