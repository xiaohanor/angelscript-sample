class URopeArrowMovementCapability : UHazeCapability
{
    default DebugCategory = RopeArrow::DebugCategory;
    default CapabilityTags.Add(RopeArrow::RopeArrowTag);

    ARopeArrow RopeArrow;

    FHazeAcceleratedVector AccRotationVector;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        RopeArrow = Cast<ARopeArrow>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(RopeArrow.bHasHitData)
            return false;

        if(!RopeArrow.bIsLaunched)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(RopeArrow.bHasHitData)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        AccRotationVector.Value = RopeArrow.ActorForwardVector;

        FHitResult InitialHit = InitialSweep();
        if(InitialHit.bStartPenetrating)
        {
            // What to do now?
            return;
        }

        if(InitialHit.bBlockingHit)
        {
            RopeArrow.SetActorLocation(InitialHit.Location);

            if(HasControl())
                RopeArrow.OnHitActor(InitialHit);
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FHitResult Hit = Sweep(DeltaTime);

        if(Hit.bBlockingHit)
        {
            RopeArrow.SetActorLocation(Hit.Location);
        }
        else
        {
            RopeArrow.ActorVelocity -= FVector::UpVector * (RopeArrow.Gravity * DeltaTime);
            const FVector NewLocation = RopeArrow.GetActorLocation() + (RopeArrow.ActorVelocity * DeltaTime);

            AccRotationVector.AccelerateTo(RopeArrow.ActorVelocity.GetSafeNormal(), 0.5, DeltaTime);

            RopeArrow.SetActorLocationAndRotation(NewLocation, FQuat::MakeFromXZ(AccRotationVector.Value, RopeArrow.ActorUpVector));
        }

        if(HasControl())
        {
            if(Hit.bBlockingHit)
                RopeArrow.OnHitActor(Hit);
        }
    }

    FHitResult InitialSweep()
    {
		FHazeTraceSettings Settings = RopeArrow.GetTraceSettings();

        const FVector Start = RopeArrow.Player.ViewLocation;
        const FVector End = RopeArrow.ActorLocation;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("InitialSweep", Hit, FHazeTraceShape::MakeSphere(RopeArrow.Sphere.SphereRadius));
        #endif

        return Hit;
    }

    FHitResult Sweep(const float DeltaTime)
    {
        FHazeTraceSettings Settings = RopeArrow.GetTraceSettings();

        const FVector Start = RopeArrow.ActorLocation;

        const FVector Delta = RopeArrow.ActorVelocity * DeltaTime;
        const FVector End = Start + Delta;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("Sweep", Hit, FHazeTraceShape::MakeSphere(RopeArrow.Sphere.SphereRadius));
        #endif

        return Hit;
    }
}