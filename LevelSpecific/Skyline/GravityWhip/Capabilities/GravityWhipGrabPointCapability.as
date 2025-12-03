class UGravityWhipGrabPointCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipGrabPoint);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::GrappleEnter);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::GravityWell);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	
	default DebugCategory = GravityWhipTags::GravityWhip;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 190;

	UGravityWhipUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.IsTargetingAny())
			return true;

		if (UserComp.IsGrabbingAny())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.IsTargetingAny())
			return false;

		if (UserComp.IsGrabbingAny())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.GrabPoints.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<UGravityWhipTargetComponent> TargetComponents;

		if (UserComp.IsGrabbingAny())
			UserComp.GetGrabbedComponents(TargetComponents);
		else
			UserComp.GetTargetedComponents(TargetComponents);

		if (TargetComponents.Num() != 0)
		{
			UserComp.GrabPoints.Reset();

			for (int i = 0; i < TargetComponents.Num(); ++i)
			{
				UGravityWhipTargetComponent TargetComp = TargetComponents[i];

				FGravityWhipGrabPoint GrabPoint;
				GrabPoint.TargetComponent = TargetComp;
				GrabPoint.PrimitiveComponent = nullptr;
				GrabPoint.RelativeLocation = FVector::ZeroVector;

				UserComp.GrabPoints.Add(GrabPoint);
			}
		}
	}
}