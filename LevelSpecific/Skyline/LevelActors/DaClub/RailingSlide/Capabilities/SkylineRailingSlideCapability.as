class USkylineRailingSlideCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USkylineRailingSlideUserComponent UserComp;
	USkylineRailingSlideComponent ActiveRailSlideComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylineRailingSlideUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 0.5)
			return false;

		if (!HasValidRailingSlideSpline())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.RailingSlide == nullptr)
			return true;

		if (WasActionStarted(ActionNames::Cancel))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		UserComp.bIsSliding = true;
		UserComp.RailingSlide = GetRailingSlideSpline();	

		ActiveRailSlideComp = UserComp.RailingSlide;
		ActiveRailSlideComp.StartRailSlideAudio(Player);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bIsSliding = false;
		ActiveRailSlideComp.StopRailSlideAudio(Player);

		UserComp.RailingSlide = nullptr;
		ActiveRailSlideComp = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("RailingSlide", 0.0, FLinearColor::Green);
	}

	bool HasValidRailingSlideSpline() const
	{
		for (auto RailingSlide : UserComp.RailingSlides)
		{
			auto SplinePosition = RailingSlide.Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
			float DistanceToSpline = (SplinePosition.WorldTransform.TransformPositionNoScale(RailingSlide.RailingOffset) - Owner.ActorLocation).Size();
			if (DistanceToSpline < UserComp.RailingSnapRange)
				return true;
		}

		return false;
	}

	USkylineRailingSlideComponent GetRailingSlideSpline()
	{
		USkylineRailingSlideComponent ClosestRailingSlide;
		float ClosestDistance = UserComp.RailingSnapRange;

		for (auto RailingSlide : UserComp.RailingSlides)
		{
			auto SplinePosition = RailingSlide.Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);

			if (Owner.ActorUpVector.GetAngleDegreesTo(SplinePosition.WorldUpVector) > 90.0)
				continue;

			float DistanceToSpline = (SplinePosition.WorldTransform.TransformPositionNoScale(RailingSlide.RailingOffset) - Owner.ActorLocation).Size();
			if (DistanceToSpline < ClosestDistance)
			{
				ClosestRailingSlide = RailingSlide;
				ClosestDistance = DistanceToSpline;
			}
		}

		return ClosestRailingSlide;
	}
};