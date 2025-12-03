class UBlizzardArrowMovementCapability : UHazeCapability
{
    default DebugCategory = BlizzardArrow::DebugCategory;
    default CapabilityTags.Add(BlizzardArrow::BlizzardArrowCapabilityTag);

    ABlizzardArrow BlizzardArrow;

    FHazeAcceleratedVector AccRotationVector;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        BlizzardArrow = Cast<ABlizzardArrow>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(BlizzardArrow.bHasHitData)
            return false;

        if(!BlizzardArrow.bIsLaunched)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(BlizzardArrow.bHasHitData)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        AccRotationVector.Value = BlizzardArrow.ActorForwardVector;

        FHitResult InitialHit = InitialSweep();
        if(InitialHit.bStartPenetrating)
        {
            // What to do now?
            return;
        }

        if(InitialHit.bBlockingHit)
        {
            BlizzardArrow.SetActorLocation(InitialHit.Location);

            if(HasControl())
                BlizzardArrow.OnHitActor(InitialHit);
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FHitResult Hit = Sweep(DeltaTime);

        if(Hit.bBlockingHit)
        {
            BlizzardArrow.SetActorLocation(Hit.Location);
        }
        else
        {
            BlizzardArrow.ActorVelocity -= FVector::UpVector * (BlizzardArrow.Gravity * DeltaTime);
            const FVector NewLocation = BlizzardArrow.GetActorLocation() + (BlizzardArrow.ActorVelocity * DeltaTime);

            AccRotationVector.AccelerateTo(BlizzardArrow.ActorVelocity.GetSafeNormal(), 0.5, DeltaTime);

            BlizzardArrow.SetActorLocationAndRotation(NewLocation, FQuat::MakeFromXZ(AccRotationVector.Value, BlizzardArrow.ActorUpVector));
        }

        if(HasControl())
        {
            if(Hit.bBlockingHit)
                BlizzardArrow.OnHitActor(Hit);
        }
    }

    FHitResult InitialSweep()
    {
		FHazeTraceSettings Settings = BlizzardArrow.GetTraceSettings();

        const FVector Start = BlizzardArrow.Player.ViewLocation;
        const FVector End = BlizzardArrow.ActorLocation;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("InitialSweep", Hit, FHazeTraceShape::MakeSphere(BlizzardArrow.Sphere.SphereRadius));
        #endif

        return Hit;
    }

    FHitResult Sweep(const float DeltaTime)
    {
        FHazeTraceSettings Settings = BlizzardArrow.GetTraceSettings();

        const FVector Start = BlizzardArrow.ActorLocation;

        const FVector Delta = BlizzardArrow.ActorVelocity * DeltaTime;
        const FVector End = Start + Delta;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("Sweep", Hit, FHazeTraceShape::MakeSphere(BlizzardArrow.Sphere.SphereRadius));
        #endif

        return Hit;
    }
}