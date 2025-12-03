struct FSteerSandFishMovementActivateParams
{
    bool bWasProgressPoint;
}

class USteerSandFishMovementCapability : UHazeCapability
{
    default TickGroup = EHazeTickGroup::BeforeMovement;
    default TickGroupOrder = 90;

    //default CapabilityTags.Add(ArenaSandFish::Tags::ArenaSandFishSteered);

    AVortexSandFish SandFish;

    float SideOffset;
    FHazeAcceleratedTransform AccRelativeOffset;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        SandFish = Cast<AVortexSandFish>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FSteerSandFishMovementActivateParams& Params) const
    {
        if(Desert::GetDesertLevelState() != EDesertLevelState::Steer)
            return false;

        Params.bWasProgressPoint = Desert::GetDesertLevelState() == Desert::GetDesertProgressPointLevelState();

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(Desert::GetDesertLevelState() != EDesertLevelState::Steer)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FSteerSandFishMovementActivateParams Params)
    {
        SandFish.bIsSteered = true;

        if(Params.bWasProgressPoint)
        {
            SandFish.SteerDistanceAlongSpline = 0;
            AccRelativeOffset.SnapTo(FTransform::Identity);
        }
        else
        {
            SandFish.SteerDistanceAlongSpline = SandFish.SteerSpline.Spline.GetClosestSplineDistanceToWorldLocation(SandFish.ActorLocation);
            const FTransform SplineTransform = GetSplineTransform(SandFish.SteerDistanceAlongSpline);
            const FTransform RelativeTransform = SandFish.ActorTransform.GetRelativeTransform(SplineTransform);
            AccRelativeOffset.SnapTo(RelativeTransform);
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        SandFish.Steering = 0;

        SandFish.Steering += SandFish.LeftInteraction.Steering;
        SandFish.Steering += SandFish.RightInteraction.Steering;

        SandFish.Steering *= 0.5;

        SandFish.Steering = Math::Clamp(SandFish.Steering, -1, 1);

        SandFish.AccSteering.AccelerateTo(SandFish.Steering, 1.5, DeltaTime);

        float Alpha = (SandFish.SteerDistanceAlongSpline / SandFish.SteerSpline.Spline.SplineLength);
        float MoveSpeed = Math::Lerp(ClimbSandFish::MaxMoveSpeed, ClimbSandFish::MinMoveSpeed, Alpha);

        SandFish.SteerDistanceAlongSpline += MoveSpeed * DeltaTime;

        const FTransform SplineTransform = GetSplineTransform(SandFish.SteerDistanceAlongSpline);

        if(ClimbSandFish::bUseVelocityWhenSteering)
        {
            SideOffset += SandFish.AccSteering.Value * ClimbSandFish::SideSteerSpeed * DeltaTime;
            SideOffset = Math::Clamp(SideOffset, -ClimbSandFish::SideSteerDistance, ClimbSandFish::SideSteerDistance);
        }
        else
        {
            SideOffset = SandFish.AccSteering.Value * ClimbSandFish::SideSteerDistance;
        }

        FVector RightOffset = SplineTransform.Rotation.RightVector * SideOffset;

        AccRelativeOffset.AccelerateTo(FTransform::Identity, 5, DeltaTime);
        FTransform NewTransform = AccRelativeOffset.Value * SplineTransform;

        FQuat NewRotation = Math::QInterpTo(Owner.ActorQuat, NewTransform.Rotation, DeltaTime, 10);
        NewTransform.SetRotation(NewRotation);

        SandFish.SetActorLocationAndRotation(NewTransform.Location + RightOffset, NewTransform.Rotation);

        HeadCollisionTest(SandFish.HeadCollider);
    }

	void HeadCollisionTest(UBoxComponent Collider)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		Trace.IgnoreActor(Owner);

		Trace.UseBoxShape(Collider);
		Trace.DebugDrawOneFrame();

		FOverlapResultArray Overlaps = Trace.QueryOverlaps(Collider.WorldLocation);
		for(auto Overlap : Overlaps)
		{
			USandFishResponseComponent ResponseComp = USandFishResponseComponent::Get(Overlap.Actor);
			if(ResponseComp != nullptr)
			{
				FVector ImpactPoint = ResponseComp.GetClosestPointOnCollision(Collider.WorldLocation);
				ResponseComp.SandFishHeadCollision(Owner, ImpactPoint);
			}
		}
	}

    FTransform GetSplineTransform(float Distance) const
    {
        FTransform Transform = SandFish.SteerSpline.Spline.GetWorldTransformAtSplineDistance(Distance);
        FVector Location = Transform.Location;
        Location.Z = Desert::GetLandscapeHeight(Owner.ActorLocation);
        Transform.SetLocation(Location);

        // FB TODO: Hard coded value to stop following terrain when transitioning to tall
        if(Location.Z > 44418.678101)
        {
            FQuat GroundRotation = GetAlignWithGroundRotation(Transform);
            Transform.SetRotation(GroundRotation);
        }

        return Transform;
    }

    FQuat GetAlignWithGroundRotation(FTransform SplineTransform) const
    {
        const float BackOffset = 1000;
        const float ForwardAdditive = 300;

        FVector BackLocation = SplineTransform.Location - SplineTransform.Rotation.ForwardVector * BackOffset;
        BackLocation.Z = Desert::GetLandscapeHeight(BackLocation);

        FVector ForwardLocation = SplineTransform.Location + SplineTransform.Rotation.ForwardVector * 2000;
        ForwardLocation.Z = Desert::GetLandscapeHeight(ForwardLocation) + ForwardAdditive;

        return FQuat::MakeFromXZ(ForwardLocation - BackLocation, FVector::UpVector);
    }
};