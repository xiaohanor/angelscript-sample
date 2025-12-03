class USummitCrystalSkullChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCrystalSkullComponent SwarmComp;
	USummitCrystalSkullSettings FlyerSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SwarmComp = USummitCrystalSkullComponent::GetOrCreate(Owner);
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!ShouldChase(TargetComp.Target, FlyerSettings.ChaseRange))
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
		if (ActiveDuration < FlyerSettings.ChaseMinDuration)
			return false;
		if (!ShouldChase(TargetComp.Target, FlyerSettings.ChaseRange))
			return true;
		return false;
	}

	bool ShouldChase(AHazeActor Target, float Range) const
	{
		if (!TargetComp.IsValidTarget(Target))
			return false;

		FVector TargetLoc = Target.ActorCenterLocation;
		if (!SwarmComp.IsAllowedLocation(TargetLoc))
			return false;

		FVector OwnLoc = Owner.ActorCenterLocation;
		if (!TargetLoc.IsWithinDist(OwnLoc, Range))
			return false;

		// Don't chase things that are already coming for us
		float MaxCosAngle = Math::Cos(Math::DegreesToRadians(FlyerSettings.ChaseMaxAngle));
		if (Target.ActorForwardVector.DotProduct((OwnLoc - TargetLoc).GetSafeNormal()) > MaxCosAngle)
			return false;	

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorCenterLocation;
		
		// Chase to a flanking position
		FTransform TargetTransform = TargetComp.Target.ActorTransform;
		FVector RelativeLoc = TargetTransform.InverseTransformPosition(OwnLoc);
		RelativeLoc.X = FlyerSettings.ChaseFlankingOffset.X;
		RelativeLoc.Y = Math::Sign(RelativeLoc.Y) * FlyerSettings.ChaseFlankingOffset.Y;
		RelativeLoc.Z = FlyerSettings.ChaseFlankingOffset.Z;
		FVector FlankingDest = TargetTransform.TransformPosition(RelativeLoc);
		FlankingDest = SwarmComp.ProjectToArea(FlankingDest);
		DestinationComp.MoveTowards(FlankingDest, FlyerSettings.ChaseSpeed);

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(TargetTransform.Location, FlankingDest, FLinearColor::Red, 20);		
			Debug::DrawDebugSphere(FlankingDest, 500, 4, FLinearColor::Red, 100);
			Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Red, 10);
		}
#endif
	}
}
