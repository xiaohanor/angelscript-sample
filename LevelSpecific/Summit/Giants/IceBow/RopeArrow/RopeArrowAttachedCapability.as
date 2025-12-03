struct FRopeArrowAttachOnActivatedParams
{
	FRopeArrowHitData HitData;
}

class URopeArrowAttachedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = RopeArrow::DebugCategory;
    default CapabilityTags.Add(RopeArrow::RopeArrowTag);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
       
    ARopeArrow RopeArrow;
	bool bHasStartedDestroying = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        RopeArrow = Cast<ARopeArrow>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FRopeArrowAttachOnActivatedParams& Params) const
    {
        if(!RopeArrow.bActive)
            return false;

        if(!RopeArrow.bHasHitData)
            return false;

		Params.HitData = RopeArrow.HitData;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(!RopeArrow.bActive)
            return true;

        if(!RopeArrow.bHasHitData)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FRopeArrowAttachOnActivatedParams Params)
    {
		RopeArrow.HitData = Params.HitData;

        Attach();

		FVector EndAttachLocation = RopeArrow.CableComp.AttachedComponent.WorldTransform.TransformPosition(RopeArrow.CableComp.EndLocation);
		FVector DirToAttachLocation = RopeArrow.ActorLocation - EndAttachLocation;

		if(DirToAttachLocation.GetAngleDegreesTo(FVector::UpVector) < 45.0)
		{
			FRotator Rotation = FRotator::MakeFromZ(DirToAttachLocation);
			RopeArrow.PoleClimb = Cast<APoleClimbActor>(SpawnActor(RopeArrow.Settings.PoleClimbActorClass, EndAttachLocation, Rotation, NAME_None, true));
			RopeArrow.PoleClimb.SetNewHeight(DirToAttachLocation.Size() - 100.0);
			FinishSpawningActor(RopeArrow.PoleClimb);
		}
		else
		{
			FRotator Rotation = FRotator::MakeFromX(DirToAttachLocation);
			RopeArrow.PerchSpline = Cast<APerchSpline>(SpawnActor(RopeArrow.Settings.PerchSplineClass, EndAttachLocation, Rotation, NAME_None, true));
			RopeArrow.PerchSpline.Spline.SplinePoints[1].RelativeLocation = FVector::ForwardVector * (DirToAttachLocation.Size() - 100);
			FinishSpawningActor(RopeArrow.PerchSpline);
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!IsBlocked())
			RopeArrow.Deactivate();
	}

    private void Attach()
    {
        RopeArrow.SetActorLocation(RopeArrow.HitData.ImpactPoint - RopeArrow.HitData.ImpactNormal * 20.0);
        RopeArrow.AttachToComponent(RopeArrow.HitData.Component, NAME_None, EAttachmentRule::KeepWorld);

		RopeArrow.SetActorTickEnabled(true);
    }
}