class UIceArrowMovementCapability : UHazeCapability
{
    default DebugCategory = IceArrow::DebugCategory;
    default CapabilityTags.Add(IceArrow::IceArrowTag);

    AIceArrow IceArrow;

    FHazeAcceleratedVector AccRotationVector;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceArrow = Cast<AIceArrow>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(IceArrow.bHasHitData)
            return false;

        if(!IceArrow.bIsLaunched)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(IceArrow.bHasHitData)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        AccRotationVector.Value = IceArrow.ActorForwardVector;

        FHitResult InitialHit = InitialSweep();
        if(InitialHit.bStartPenetrating)
        {
            // What to do now?
            return;
        }

        if(InitialHit.bBlockingHit)
        {
            IceArrow.SetActorLocation(InitialHit.Location);
            
            if(HasControl())
                IceArrow.OnHitActor(InitialHit);
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FHitResult Hit = Sweep(DeltaTime);

        if(Hit.bBlockingHit)
        {
            IceArrow.SetActorLocation(Hit.Location);
        }
        else
        {
            IceArrow.ActorVelocity -= FVector::UpVector * (IceArrow.Gravity * DeltaTime);
            const FVector NewLocation = IceArrow.GetActorLocation() + (IceArrow.ActorVelocity * DeltaTime);

            AccRotationVector.AccelerateTo(IceArrow.ActorVelocity.GetSafeNormal(), 0.5, DeltaTime);

            IceArrow.SetActorLocationAndRotation(NewLocation, FQuat::MakeFromXZ(AccRotationVector.Value, IceArrow.ActorUpVector));
        }

        if(HasControl())
        {
            if(Hit.bBlockingHit)
                IceArrow.OnHitActor(Hit);
        }
    }

    FHitResult InitialSweep()
    {
		FHazeTraceSettings Settings = IceArrow.GetTraceSettings();

        const FVector Start = IceArrow.Player.ViewLocation;
        const FVector End = IceArrow.ActorLocation;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("InitialSweep", Hit, FHazeTraceShape::MakeSphere(IceArrow.Sphere.SphereRadius));
        #endif

        return Hit;
    }

    FHitResult Sweep(const float DeltaTime)
    {
        FHazeTraceSettings Settings = IceArrow.GetTraceSettings();

        const FVector Start = IceArrow.ActorLocation;

        const FVector Delta = IceArrow.ActorVelocity * DeltaTime;
        const FVector End = Start + Delta;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("Sweep", Hit, FHazeTraceShape::MakeSphere(IceArrow.Sphere.SphereRadius));
        #endif

        return Hit;
    }
}