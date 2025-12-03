struct FWindArrowDeactivatedParams
{
	bool bShouldDespawn = false;
}

class UWindArrowMovementCapability : UHazeCapability
{
    default DebugCategory = WindArrow::DebugCategory;
    default CapabilityTags.Add(WindArrow::WindArrowTag);

    AWindArrow WindArrow;

    FHazeAcceleratedVector AccRotationVector;
	bool bPassedPlayer = false;
	float PreviousPlayerSqrDist = MAX_flt;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        WindArrow = Cast<AWindArrow>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(WindArrow.bHasHitData)
            return false;

        if(!WindArrow.bIsLaunched)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate(FWindArrowDeactivatedParams& Params) const
    {
        if(WindArrow.bHasHitData)
            return true;

		if(ActiveDuration > 5.0)
		{
			Params.bShouldDespawn = true;
			return true;
		}

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		PreviousPlayerSqrDist = MAX_flt;
		bPassedPlayer = false;
        AccRotationVector.Value = WindArrow.ActorForwardVector;

        FHitResult InitialHit = InitialSweep();
        if(InitialHit.bStartPenetrating)
        {
            // What to do now?
            return;
        }

        if(InitialHit.bBlockingHit)
        {
            WindArrow.SetActorLocation(InitialHit.Location);
            
            if(HasControl())
                WindArrow.OnHitActor(InitialHit);
        }
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FWindArrowDeactivatedParams Params)
	{
		if(Params.bShouldDespawn)
			WindArrow.WindArrowPlayerComp.RecycleWindArrow(WindArrow);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FHitResult Hit = Sweep(DeltaTime);

		if(!bPassedPlayer)
		{
			float NewSqrDist = WindArrow.Player.OtherPlayer.ActorCenterLocation.DistSquared(WindArrow.ActorLocation);
			if(NewSqrDist > PreviousPlayerSqrDist)
			{
				if(PreviousPlayerSqrDist < Math::Square(WindArrow.WindArrowPlayerComp.Settings.ExtraPlayerKnockdownRadius))
					WindArrow.ApplyKnockdown(WindArrow.Player.OtherPlayer, 300.0, 0.5);
			}

			PreviousPlayerSqrDist = NewSqrDist;
		}

        if(Hit.bBlockingHit)
        {
            WindArrow.SetActorLocation(Hit.Location);
        }
        else
        {
            WindArrow.ActorVelocity -= FVector::UpVector * (WindArrow.Gravity * DeltaTime);
            const FVector NewLocation = WindArrow.GetActorLocation() + (WindArrow.ActorVelocity * DeltaTime);

            AccRotationVector.AccelerateTo(WindArrow.ActorVelocity.GetSafeNormal(), 0.5, DeltaTime);

            WindArrow.SetActorLocationAndRotation(NewLocation, FQuat::MakeFromXZ(AccRotationVector.Value, WindArrow.ActorUpVector));
        }

        if(HasControl())
        {
            if(Hit.bBlockingHit)
                WindArrow.OnHitActor(Hit);
        }
    }

    FHitResult InitialSweep()
    {
		FHazeTraceSettings Settings = WindArrow.GetTraceSettings();

        const FVector Start = WindArrow.Player.ViewLocation;
        const FVector End = WindArrow.ActorLocation;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("InitialSweep", Hit, FHazeTraceShape::MakeSphere(WindArrow.Sphere.SphereRadius));
        #endif

        return Hit;
    }

    FHitResult Sweep(const float DeltaTime)
    {
        FHazeTraceSettings Settings = WindArrow.GetTraceSettings();

        const FVector Start = WindArrow.ActorLocation;

        const FVector Delta = WindArrow.ActorVelocity * DeltaTime;
        const FVector End = Start + Delta;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("Sweep", Hit, FHazeTraceShape::MakeSphere(WindArrow.Sphere.SphereRadius));
        #endif

        return Hit;
    }
}