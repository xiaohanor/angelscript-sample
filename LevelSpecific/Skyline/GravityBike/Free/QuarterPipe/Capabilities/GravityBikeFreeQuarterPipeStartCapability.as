struct FGravityBikeFreeQuarterPipeStartActivateParams
{
	FGravityBikeFreeQuarterPipeRelativeToSplineData RelativeToSplineData;
};

class UGravityBikeFreeQuarterPipeStartCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::QuarterPipeTags::GravityBikeFreeQuarterPipe);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeQuarterPipeComponent QuarterPipeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		QuarterPipeComp = UGravityBikeFreeQuarterPipeComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeFreeQuarterPipeStartActivateParams& Params) const
	{
		if(QuarterPipeComp.IsJumping())
			return false;

		if(GravityBike.IsAirborne.Get())
			return false;

		Params.RelativeToSplineData = CalculateRelativeToSplineData();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(QuarterPipeComp.IsJumping())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeFreeQuarterPipeStartActivateParams Params)
	{
		QuarterPipeComp.RelativeData = Params.RelativeToSplineData;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(QuarterPipeComp.RelativeData.FrameNumber == Time::FrameNumber)
			return;

		auto CurrentRelativeData = CalculateRelativeToSplineData();

		if(CurrentRelativeData.RelativeTransform.Location.SizeSquared() < Math::Square(GravityBikeFree::QuarterPipe::StartDistanceToSpline))
		{
			if(QuarterPipeComp.RelativeData.RelativeTransform.Location.Z < 0 && CurrentRelativeData.RelativeTransform.Location.Z > 0)
			{
				auto MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
				QuarterPipeComp.JumpData = FGravityBikeFreeQuarterPipeJumpData(CurrentRelativeData.Spline, GravityBike.ActorLocation, MoveComp.Velocity);
			}
		}

		QuarterPipeComp.RelativeData = CurrentRelativeData;
	}

	AGravityBikeFreeQuarterPipeSplineActor FindClosestSpline() const
	{
		AGravityBikeFreeQuarterPipeSplineActor ClosestSpline;
		float ClosestSplineDistance = BIG_NUMBER;
		
		TListedActors<AGravityBikeFreeQuarterPipeSplineActor> Splines;
		for(AGravityBikeFreeQuarterPipeSplineActor Spline : Splines)
		{
			const FVector Location = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(GravityBike.ActorLocation);
			const float Distance = GravityBike.ActorLocation.Distance(Location);
			if(Distance < ClosestSplineDistance)
			{
				ClosestSpline = Spline;
				ClosestSplineDistance = Distance;
			}
		}

		return ClosestSpline;
	}

	FGravityBikeFreeQuarterPipeRelativeToSplineData CalculateRelativeToSplineData() const
	{
		FGravityBikeFreeQuarterPipeRelativeToSplineData RelativeToSplineData;
		RelativeToSplineData.FrameNumber = Time::FrameNumber;
		RelativeToSplineData.Spline = FindClosestSpline();

		if(RelativeToSplineData.Spline == nullptr)
		{
			return RelativeToSplineData;
		}

		auto SplineTransform = RelativeToSplineData.Spline.Spline.GetClosestSplineWorldTransformToWorldLocation(GravityBike.ActorLocation);
		RelativeToSplineData.RelativeTransform = GravityBike.ActorTransform.GetRelativeTransform(SplineTransform);
		return RelativeToSplineData;
	}
};