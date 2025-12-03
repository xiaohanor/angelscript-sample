class UWindJavelinMovementCapability : UHazeCapability
{
    default DebugCategory = WindJavelin::DebugCategory;
    default CapabilityTags.Add(WindJavelin::WindJavelinProjectileTag);

    default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

    AWindJavelin WindJavelin;

    FHazeAcceleratedVector AccRotationVector;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        WindJavelin = Cast<AWindJavelin>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(WindJavelin.GetHasValidHitData())
            return false;

        if(!WindJavelin.bIsThrown)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(WindJavelin.GetHasValidHitData())
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        AccRotationVector.Value = Owner.ActorForwardVector;

        FHitResult InitialHit = InitialSweep();
        if(InitialHit.bStartPenetrating)
        {
            // What to do now?
            return;
        }

        if(InitialHit.bBlockingHit)
        {
            WindJavelin.SetActorLocation(InitialHit.Location);
            WindJavelin.OnHitActor(InitialHit);
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FHitResult Hit = Sweep(DeltaTime);

        if(Hit.bBlockingHit)
        {
            WindJavelin.SetActorLocation(Hit.Location);
        }
        else
        {
            WindJavelin.ActorVelocity -= FVector::UpVector * (WindJavelin.Gravity * DeltaTime);
            const FVector NewLocation = WindJavelin.GetActorLocation() + (WindJavelin.ActorVelocity * DeltaTime);

            AccRotationVector.AccelerateTo(WindJavelin.ActorVelocity.GetSafeNormal(), 0.5, DeltaTime);

            WindJavelin.SetActorLocationAndRotation(NewLocation, FQuat::MakeFromXZ(AccRotationVector.Value, WindJavelin.ActorUpVector));
        }

        if(Hit.bBlockingHit)
            WindJavelin.OnHitActor(Hit);
    }

    FHitResult InitialSweep()
    {
		FHazeTraceSettings Settings = GetTraceSettings();

        const FVector Start = WindJavelin.Player.ViewLocation;
        const FVector End = WindJavelin.ActorLocation;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("Initial Sweep", Hit, FHazeTraceShape::MakeSphere(WindJavelin.Sphere.SphereRadius));
        #endif

        return Hit;
    }

    FHitResult Sweep(const float DeltaTime)
    {
		FHazeTraceSettings Settings = GetTraceSettings();

        // Start tracing from where the hand held the javelin, to prevent hitting the inside of things when thrown close to a wall
        const FVector Start = WindJavelin.ActorLocation + WindJavelin.ActorRotation.RotateVector(WindJavelin.Settings.HandHoldRelativeLocation);

        // But get the end relative to the front of the spear
        const FVector Delta = WindJavelin.GetActorVelocity() * DeltaTime;
        const FVector End = WindJavelin.ActorLocation + Delta;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("Sweep", Hit, FHazeTraceShape::MakeSphere(WindJavelin.Sphere.SphereRadius));
        #endif

        return Hit;
    }

    FHazeTraceSettings GetTraceSettings() const
    {
        FHazeTraceSettings Settings = Trace::InitChannel(ETraceTypeQuery::Visibility);
        Settings.UseSphereShape(WindJavelin.Sphere.SphereRadius);
        Settings.IgnorePlayers();
		Settings.SetTraceComplex(false);
        return Settings;
    }
}