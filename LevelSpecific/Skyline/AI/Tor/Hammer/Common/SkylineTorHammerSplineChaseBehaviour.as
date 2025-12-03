
// Move towards enemy
class USkylineTorHammerSplineChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	ASplineActor SplineActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SplineActor = TListedActors<ASkylineTorReferenceManager>().Single.CircleMovementSplineActor;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.ChaseMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride) 
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.ChaseMinRange))
		{
			Cooldown.Set(BasicSettings.ChaseMinRangeCooldown);
			return;
		}

		float Distance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
		float TargetDistance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(TargetComp.Target.ActorLocation);

		bool bForward = TargetDistance > Distance;
		if(Math::Abs(Distance - TargetDistance) > SplineActor.Spline.SplineLength * 0.5)
			bForward = !bForward;

		// Keep moving towards target!
		DestinationComp.MoveAlongSpline(SplineActor.Spline, BasicSettings.ChaseMoveSpeed, bForward);
	}
}