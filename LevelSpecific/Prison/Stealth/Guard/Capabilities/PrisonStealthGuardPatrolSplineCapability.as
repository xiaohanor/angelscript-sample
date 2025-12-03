class UPrisonStealthGuardPatrolSplineCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthGuard);
	default CapabilityTags.Add(PrisonStealthTags::BlockedWhileStunned);
	default CapabilityTags.Add(PrisonStealthTags::BlockedWhileSearching);

	APrisonStealthGuard StealthGuard;
	UPrisonStealthGuardPatrolComponent PatrolComp;
	float DistanceAlongSpline = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StealthGuard = Cast<APrisonStealthGuard>(Owner);
		PatrolComp = UPrisonStealthGuardPatrolComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonStealthGuardPatrolSplineActivatedParams& Params) const
	{
		if(!PatrolComp.HasAnySections())
			return false;

		if(!PatrolComp.GetCurrentSectionIsFollowSpline())
			return false;

		FPrisonStealthGuardSection Section = PatrolComp.GetCurrentSection();
		UHazeSplineComponent Spline = Section.GetSpline();
		
		float Distance = Spline.GetClosestSplineDistanceToWorldLocation(StealthGuard.ActorLocation);
		if(Section.Direction == EPrisonStealthGuardSplineDir::Reverse)
			Distance = Spline.SplineLength - Distance;

		Params.Distance = Distance;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PatrolComp.HasAnySections())
			return true;

		if(!PatrolComp.GetCurrentSectionIsFollowSpline())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonStealthGuardPatrolSplineActivatedParams Params)
	{
		DistanceAlongSpline = Params.Distance;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		FPrisonStealthGuardSection Section = PatrolComp.GetCurrentSection();
		UHazeSplineComponent Spline = Section.GetSpline();
		const bool bForward = Section.Direction == EPrisonStealthGuardSplineDir::Forward;

		// Move along the spline
		DistanceAlongSpline += PatrolComp.FollowSpeed * DeltaTime;

		// Flip the alpha to (Max - Alpha) if we are reversing
		const float AlphaDistanceAlongSpline = bForward ? DistanceAlongSpline : Spline.GetSplineLength() - DistanceAlongSpline;

		// Get the new location and rotation from the spline alpha
		StealthGuard.TargetLocation = Spline.GetWorldLocationAtSplineDistance(AlphaDistanceAlongSpline);
		StealthGuard.TargetYaw = Spline.GetWorldRotationAtSplineDistance(AlphaDistanceAlongSpline).Rotator().Yaw;

		// Flip the rotation if we are reversing
		if(!bForward)
			StealthGuard.TargetYaw = StealthGuard.TargetYaw + 180.0;

		// If we have moved the entire spline, go to the next section
		if(DistanceAlongSpline >= Spline.GetSplineLength())
			HasReachedEnd();
	}

	void TickRemote(float DeltaTime)
	{
	}

	void HasReachedEnd()
	{
		DistanceAlongSpline = 0.0;
		PatrolComp.GoToNextSection();
	}
}

struct FPrisonStealthGuardPatrolSplineActivatedParams
{
	float Distance;
}