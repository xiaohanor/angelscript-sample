struct FBlizzardArrowAttachOnActivatedParams
{
	FBlizzardArrowHitData HitData;
}

struct FBlizzardArrowAttachOnDeactivatedParams
{
	bool bLifetimeExpired = false;
}

class UBlizzardArrowAttachedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = BlizzardArrow::DebugCategory;
    default CapabilityTags.Add(BlizzardArrow::BlizzardArrowCapabilityTag);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
       
    ABlizzardArrow BlizzardArrow;
	float LifeTime;
	bool bHasStartedDestroying = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        BlizzardArrow = Cast<ABlizzardArrow>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FBlizzardArrowAttachOnActivatedParams& Params) const
    {
        if(!BlizzardArrow.bActive)
            return false;

        if(!BlizzardArrow.GetHasValidAttachment())
            return false;

		Params.HitData = BlizzardArrow.HitData;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate(FBlizzardArrowAttachOnDeactivatedParams& Params) const
    {
        if(!BlizzardArrow.bActive)
            return true;

        if(!BlizzardArrow.GetHasValidAttachment())
            return true;

		if(ActiveDuration > LifeTime)
		{
			Params.bLifetimeExpired = true;
			return true;
		}

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FBlizzardArrowAttachOnActivatedParams Params)
    {
		BlizzardArrow.HitData = Params.HitData;

        Attach();

        UWindJavelinResponseComponent ResponseComponent = UWindJavelinResponseComponent::Get(BlizzardArrow.HitData.Component.Owner);
        LifeTime = (ResponseComponent != nullptr && ResponseComponent.bSetWindJavelinLifetime) ? ResponseComponent.WindJavelinLifetime : BlizzardArrow.Settings.Lifetime;
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FBlizzardArrowAttachOnDeactivatedParams Params)
	{
		if(!IsBlocked() && Params.bLifetimeExpired)
			BlizzardArrow.Deactivate();
	}

    private void Attach()
    {
		if(HasControl())
        	check(BlizzardArrow.GetHasValidAttachment());

        BlizzardArrow.SetActorLocationAndRotation(BlizzardArrow.HitData.ImpactPoint - BlizzardArrow.HitData.ImpactNormal * 20.0, (-BlizzardArrow.HitData.ImpactNormal).ToOrientationQuat());
        BlizzardArrow.AttachToComponent(BlizzardArrow.HitData.Component, NAME_None, EAttachmentRule::KeepWorld);

		UWindJavelinResponseComponent AttachResponseComp = UWindJavelinResponseComponent::Get(BlizzardArrow.HitData.Component.Owner);
		if (AttachResponseComp != nullptr)
			AttachResponseComp.AttachWindJavelin(BlizzardArrow);

		BlizzardArrow.SetActorTickEnabled(true);

        // Filip TODO: Tracing for nearby objects at the start is an ugly solution, but it works for now.
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseSphereShape(BlizzardArrow.WindJavelinConeComponent.Height);
		Trace.IgnorePlayers();

		FOverlapResultArray NearbyOverlaps = Trace.QueryOverlaps(BlizzardArrow.WindJavelinConeComponent.CenterLocation);

		for(auto Overlap : NearbyOverlaps)
		{
			if (Overlap.Actor == nullptr)
				continue;

			UWindJavelinResponseComponent Component = UWindJavelinResponseComponent::Get(Overlap.Actor);
			if(Component == nullptr)
				continue;

			BlizzardArrow.ResponseComponentsToInfluence.Add(FWindJavelinResponseComponentData(Component));
		}
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
			for(auto& Response : BlizzardArrow.ResponseComponentsToInfluence)
			{
				if(Response.Component.Owner == BlizzardArrow.HitData.Component.Owner)
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
					}
					else
						continue;	// The zone is not in the zone and did not enter, skip
				}

				check(Response.bIsActive);

				FWindJavelinEventData Data;
				Data.Origin = BlizzardArrow.GetActorLocation();
				Data.Force = BlizzardArrow.WindJavelinConeComponent.CalculateAccelerationAtLocation(Location);

				Response.Component.ApplyForce(Data);
			}
		}

        auto AttachedTo = UWindJavelinResponseComponent::Get(BlizzardArrow.HitData.Component.Owner);
        if(AttachedTo != nullptr && AttachedTo.bAffectFauxPhysics)
		    FauxPhysics::ApplyFauxImpulseToParentsAt(BlizzardArrow.HitData.Component, BlizzardArrow.ActorLocation, -BlizzardArrow.WindJavelinConeComponent.GetFullWindForce());
	}

    bool IsPointInsideCone(const FVector& Point)
	{
		return BlizzardArrow.WindJavelinConeComponent.DistanceToCone(Point) < KINDA_SMALL_NUMBER;
	}
}