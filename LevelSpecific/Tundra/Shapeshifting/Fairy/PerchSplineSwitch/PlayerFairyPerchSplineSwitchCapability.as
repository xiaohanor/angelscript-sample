class UTundraPlayerFairyPerchSplineSwitchCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerPerchComponent PerchComp;
	UPlayerMovementComponent MoveComp;

	// If inputting within this amount of degrees of the forward vector of the connected spline we will enter that spline
	// (this is only used when we are on a main spline going to a non-main one)
	const float DegreeInputExtents = 45.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerFairyPerchSplineSwitchActivatedParams& Params) const
	{
		if(PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
			return false;

		auto SwitchableComp = UTundraFairyPerchSplineSwitchableComponent::Get(PerchComp.Data.ActiveSpline);
		if(SwitchableComp == nullptr)
			return false;

		APerchSpline PerchSpline = GetBestPerchSplineSwitch(SwitchableComp);
		if(PerchSpline == nullptr)
			return false;

		Params.PerchSpline = PerchSpline;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerFairyPerchSplineSwitchActivatedParams Params)
	{
		Player.BlockCapabilities(PlayerPerchPointTags::PerchPointSpline, this);
		Player.UnblockCapabilities(PlayerPerchPointTags::PerchPointSpline, this);

		PerchComp.Data.TargetedPerchPoint = UPerchPointComponent::Get(Params.PerchSpline);

		PerchComp.StartPerching(PerchComp.Data.TargetedPerchPoint, false);
		PerchComp.bIsLandingOnSpline = true;
		PerchComp.Data.bInPerchSpline = true;
	}

	APerchSpline GetBestPerchSplineSwitch(UTundraFairyPerchSplineSwitchableComponent SwitchableComp) const
	{
		FVector MoveInput = MoveComp.NonLockedMovementInput;
		FVector LockedMoveInput = MoveComp.MovementInput;
		if(MoveInput.IsNearlyZero())
			return nullptr;

		FSplinePosition CurrentSplinePosition = SwitchableComp.OwnerPerchSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		FSplinePosition PredictedSplinePosition = CurrentSplinePosition;
		float Delta = CurrentSplinePosition.WorldRotation.ForwardVector.DotProduct(MoveComp.Velocity * Time::GetActorDeltaSeconds(Player));
		PredictedSplinePosition.Move(Delta);

		for(int i = 0; i < SwitchableComp.ConnectedPerchSplines.Num(); i++)
		{
			APerchSpline Spline = SwitchableComp.ConnectedPerchSplines[i];
			FTundraFairyPerchSplineSwitchableSplineData SplineData = SwitchableComp.ConnectedPerchSplinesData[i];

			// If we haven't passed the distance of the connection continue to next spline!
			if(Math::Sign(CurrentSplinePosition.CurrentSplineDistance - SplineData.DistanceOfConnection) == Math::Sign(PredictedSplinePosition.CurrentSplineDistance - SplineData.DistanceOfConnection))
				continue;

			if(SwitchableComp.bIsMainSpline)
			{
				float DegreesToSpline = SplineData.InitialForward.GetAngleDegreesTo(MoveInput);
				float DegreesToCurrent = LockedMoveInput.GetAngleDegreesTo(MoveInput);
				
				if(DegreesToCurrent < DegreesToSpline)
					continue;

				if(DegreesToSpline > DegreeInputExtents)
					continue;

				return Spline;
			}
			else
			{
				return Spline;
			}
		}

		return nullptr;
	}
}

struct FTundraPlayerFairyPerchSplineSwitchActivatedParams
{
	APerchSpline PerchSpline;
}