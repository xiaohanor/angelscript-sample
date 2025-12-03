struct FWindJavelinAttachOnActivatedParams
{
	FHitResult HitData;	// FB TODO: I assume that syncing this is very wasteful?
}

class UWindJavelinAttachedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = WindJavelin::DebugCategory;
    default CapabilityTags.Add(WindJavelin::WindJavelinProjectileTag);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
       
    AWindJavelin WindJavelin;
	float LifeTime;
	bool bHasStartedDestroying = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        WindJavelin = Cast<AWindJavelin>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FWindJavelinAttachOnActivatedParams& Params) const
    {
        if(WindJavelin.bPreparedToDestroy)
            return false;

        if(!WindJavelin.GetHasValidAttachment())
            return false;

		Params.HitData = WindJavelin.HitData;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(WindJavelin.bPreparedToDestroy)
            return true;

        if(!WindJavelin.GetHasValidAttachment())
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FWindJavelinAttachOnActivatedParams Params)
    {
		WindJavelin.HitData = Params.HitData;

        UWindJavelinResponseComponent ResponseComponent = UWindJavelinResponseComponent::Get(WindJavelin.HitData.Actor);
        LifeTime = (ResponseComponent != nullptr && ResponseComponent.bSetWindJavelinLifetime) ? ResponseComponent.WindJavelinLifetime : WindJavelin.Settings.Lifetime;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        WindTick(DeltaTime);
    }

    void WindTick(float DeltaTime)
	{
		if(HasControl())
		{
			for(auto& Response : WindJavelin.ResponseComponentsToInfluence)
			{
				if(Response.Component.Owner == WindJavelin.HitData.Actor)
					continue;

				AHazeActor HazeActor = Cast<AHazeActor>(Response.Component.Owner);
				const FVector Location = HazeActor != nullptr ? HazeActor.GetActorCenterLocation() : Response.Component.Owner.GetActorLocation();

				if(Response.bIsActive)
				{
					// If it is active, check if it has left the zone
					if(!IsPointInsideCone(Location))
					{
						// Deactivate and call OnExit if it has left the zone
						Response.bIsActive = false;
						Response.Component.ExitWindCone(WindJavelin);
						continue;
					}
				}
				else
				{
					// If it is inactive, check if it has entered the zone
					if(IsPointInsideCone(Location))
					{
						// Activate and call OnEnter if it has entered the zone
						Response.bIsActive = true;
						Response.Component.EnterWindCone(WindJavelin);
					}
					else
						continue;	// The zone is not in the zone and did not enter, skip
				}

				check(Response.bIsActive);

				FWindJavelinEventData Data;
				Data.Origin = WindJavelin.GetActorLocation();
				Data.Force = WindJavelin.WindJavelinConeComponent.CalculateAccelerationAtLocation(Location);

				Response.Component.ApplyForce(Data);
			}
		}

        auto AttachedTo = UWindJavelinResponseComponent::Get(WindJavelin.HitData.Actor);
        // if(AttachedTo != nullptr && AttachedTo.bAffectFauxPhysics)
		//     ApplyFauxForceToParentsAt(WindJavelin.HitData.Component, WindJavelin.ActorLocation, -WindJavelin.WindJavelinConeComponent.GetFullWindForce());
	}

    bool IsPointInsideCone(const FVector& Point)
	{
		return WindJavelin.WindJavelinConeComponent.DistanceToCone(Point) < KINDA_SMALL_NUMBER;
	}
}