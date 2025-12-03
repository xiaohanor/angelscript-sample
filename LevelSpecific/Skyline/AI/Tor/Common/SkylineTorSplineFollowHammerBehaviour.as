class USkylineTorSplineFollowHammerBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Follow");
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorSettings Settings;
	ASplineActor SplineActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		SplineActor = TListedActors<ASkylineTorReferenceManager>().Single.CircleMovementSplineActor;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!HoldHammerComp.bDetached)
			return false;
		if(Owner.ActorLocation.IsWithinDist(HoldHammerComp.Hammer.ActorLocation, Settings.FollowHammerMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLocation = HoldHammerComp.Hammer.ActorLocation - HoldHammerComp.Hammer.ActorForwardVector * 1000;
		if (!Owner.ActorLocation.IsWithinDist(TargetLocation, Settings.FollowHammerMinRange))
		{
			float Distance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
			float TargetDistance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(TargetLocation);

			bool bForward = TargetDistance > Distance;
			if(Math::Abs(Distance - TargetDistance) > SplineActor.Spline.SplineLength * 0.5)
				bForward = !bForward;

			DestinationComp.MoveAlongSpline(SplineActor.Spline, Settings.FollowHammerMoveSpeed, bForward);
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(HoldHammerComp.Hammer.TargetingComponent.Target);
		if(Player != nullptr && TargetComp.Target != Player.OtherPlayer)
			TargetComp.SetTarget(Player.OtherPlayer);
		if(TargetComp.Target != nullptr)
			DestinationComp.RotateTowards(TargetComp.Target);
	}
}
