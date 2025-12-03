class USummitWyrmFollowSplineBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitWyrmFollowSplineComponent SplineFollowComp;
	UHazeSplineComponent Spline;
	USummitWyrmSettings WyrmSettings;
	UHazeCapsuleCollisionComponent CollisionComp;
	bool bDoneFollowingSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SplineFollowComp = USummitWyrmFollowSplineComponent::Get(Owner);
		WyrmSettings = USummitWyrmSettings::GetSettings(Owner);
		UBasicAIMovementSettings::SetSplineFollowCaptureDistance(Owner, 10000.0, this, EHazeSettingsPriority::Defaults);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");;
		CollisionComp = Cast<AHazeCharacter>(Owner).CapsuleComponent;
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bDoneFollowingSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bDoneFollowingSpline)
			return false;
		if (SplineFollowComp.Splines.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (bDoneFollowingSpline)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Spline = UHazeSplineComponent::Get(SplineFollowComp.Splines[0]);
		CollisionComp.AddComponentCollisionBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		CollisionComp.RemoveComponentCollisionBlocker(this);

		// Find new target
		TargetComp.Target = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveAlongSpline(Spline, WyrmSettings.FollowSplineSpeed);
		if (DestinationComp.IsAtSplineEnd(Spline, WyrmSettings.FollowSplineSpeed * 0.1))
			bDoneFollowingSpline = true;

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool) 
			Spline.DrawDebug(200, Thickness = 10.0);
#endif
	}
}
