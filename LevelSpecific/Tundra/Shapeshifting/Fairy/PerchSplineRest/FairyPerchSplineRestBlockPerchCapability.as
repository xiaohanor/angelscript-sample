class UFairyPerchSplineRestBlockPerchCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerPerchComponent PerchComp;
	UPlayerMovementComponent MoveComp;

	APerchSpline RelevantSplineActor;
	int RelevantRestDirection;
	UFairyPerchSplineRestManagerComponent RelevantRestManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchComp = UPlayerPerchComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		if(PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
			return;
		
		APerchSpline SplineActor = PerchComp.Data.ActiveSpline;
		auto RestManager = UFairyPerchSplineRestManagerComponent::Get(SplineActor);
		if(RestManager == nullptr)
			return;

		for(int i = 0; i < RestManager.SortedRestComponents.Num(); i++)
		{
			auto RestComp = RestManager.SortedRestComponents[i];
			TemporalLog.Point(f"Rest Component {i + 1}", RestComp.WorldLocation, 40.f, RestManager.IsStartComponent(i) ? FLinearColor::Green : FLinearColor::Red);
		}

	}
#endif

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FFairyPerchSplineRestBlockPerchActivatedParams& Params) const
	{
		if(PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
			return false;
		
		APerchSpline SplineActor = PerchComp.Data.ActiveSpline;
		auto RestManager = UFairyPerchSplineRestManagerComponent::Get(SplineActor);
		if(RestManager == nullptr)
			return false;

		float SplineDistance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		int RestDirection = RestManager.GetValidRestDirection(SplineDistance);
		if(RestDirection == 0)
			return false;

		FTransform SplineTransform = SplineActor.Spline.GetWorldTransformAtSplineDistance(SplineDistance);
		float Input = SplineTransform.Rotation.RightVector.DotProduct(MoveComp.NonLockedMovementInput);
		if(Math::Sign(Input) != RestDirection)
			return false;

		if(Math::Abs(Input) < 0.3)
			return false;

		Params.RelevantPerchSpline = SplineActor;
		Params.RelevantRestDirection = RestDirection;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		float SplineDistance = RelevantSplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);

		// If we have exited the rest zone we want to allow entering the perch spline again no matter what!
		int RestDirection = RelevantRestManager.GetValidRestDirection(SplineDistance);
		if(RelevantRestDirection != RestDirection)
			return true;

		FTransform SplineTransform = RelevantSplineActor.Spline.GetWorldTransformAtSplineDistance(SplineDistance);

		FVector PredictedLocation = Player.ActorLocation + Player.ActorVelocity * Time::GetActorDeltaSeconds(Player);
		FVector SplineToPlayer = PredictedLocation - SplineTransform.Location;
		float SignedDistanceFromSplineToPlayer = SplineTransform.Rotation.RightVector.DotProduct(SplineToPlayer);
		if(RelevantRestDirection == -1)
			SignedDistanceFromSplineToPlayer = -SignedDistanceFromSplineToPlayer;

		// If we got to the wrong side of the spline, we should enter the spline again!
		if(SignedDistanceFromSplineToPlayer < -5.0)
			return true;

		if(SignedDistanceFromSplineToPlayer > 10.0)
			return false;

		float Input = SplineTransform.Rotation.RightVector.DotProduct(MoveComp.NonLockedMovementInput);
		if(Math::Sign(Input) == RelevantRestDirection)
			return false;

		if(Math::Abs(Input) < 0.1)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FFairyPerchSplineRestBlockPerchActivatedParams Params)
	{
		RelevantSplineActor = Params.RelevantPerchSpline;
		RelevantRestDirection = Params.RelevantRestDirection;
		RelevantRestManager = UFairyPerchSplineRestManagerComponent::Get(RelevantSplineActor);
		Player.BlockCapabilities(PlayerMovementTags::Perch, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Perch, this);
	}
}

struct FFairyPerchSplineRestBlockPerchActivatedParams
{
	APerchSpline RelevantPerchSpline;
	int RelevantRestDirection;
}