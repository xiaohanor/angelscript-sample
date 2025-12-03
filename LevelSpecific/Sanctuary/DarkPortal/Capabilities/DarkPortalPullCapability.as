class UDarkPortalPullCapability : UHazeCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalPull);

	default TickGroupOrder = 106;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADarkPortalActor Portal;

	// Special case because the thing portal is attached to can rotate
	float LastAngle = 0;
	float SpecialcaseMultiplyForce = 3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Portal = Cast<ADarkPortalActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Portal.HasActiveGrab())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Portal.HasActiveGrab())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastAngle = Portal.TargetData.SceneComponent.WorldRotation.Yaw;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Portal.TargetData.bSpecialCasePullBecauseTargetCanRotate)
			TickActiveSpecialcase(DeltaTime);
		else
			TickActiveNormal(DeltaTime);
	}

	private void TickActiveNormal(float DeltaTime)
	{
		int NumActiveGrabbed = Portal.GetNumActiveGrabbedComponents();
		if (NumActiveGrabbed == 0)
			return;

		// Apply force to all grabbed target components
		FVector AccumulatedOffset = FVector::ZeroVector;
		for (auto& Grab : Portal.Grabs)
		{
			// Ensure we have something to apply force to
			int NumTargets = Grab.TargetComponents.Num();
			if (NumTargets == 0 || !Grab.bHasTriggeredResponse)
				continue;

			for (auto TargetComponent : Grab.TargetComponents)
			{
				auto AffectedComponent = DarkPortal::GetParentForceAnchor(TargetComponent);
				FVector AffectedToPortal = (Portal.OriginLocation - AffectedComponent.WorldLocation);

				if (Grab.ResponseComponent != nullptr)
				{
					FVector PortalOrigin = Grab.ResponseComponent.GetOriginLocationForPortal(Portal);
					AffectedToPortal = (PortalOrigin - AffectedComponent.WorldLocation);

					float DistributedForce = Grab.ResponseComponent.PullForce / NumTargets;
					float Alpha = Math::Clamp(AffectedToPortal.Size() / DarkPortal::Grab::ForceAlphaRadius, 0.0, 1.0);
					FVector Force = (AffectedToPortal.GetSafeNormal() * DistributedForce * Alpha);

					Grab.ResponseComponent.ApplyGrabForce(Portal, TargetComponent, Force);
					Grab.ResponseComponent.ApplyGrabTargetLocation(Portal, TargetComponent, PortalOrigin, Portal.ActorForwardVector);
				}

				AccumulatedOffset += AffectedToPortal;
			}
		}

		// Apply force to the attached actor towards the opposite direction
		//  magnitude comes from attached response component
		if (Portal.AttachResponse != nullptr)
		{
			float AverageDistance = AccumulatedOffset.Size() / NumActiveGrabbed;
			float Alpha = Math::Clamp(AverageDistance / DarkPortal::Grab::ForceAlphaRadius, 0.0, 1.0);
			FVector Force = -AccumulatedOffset.GetSafeNormal() * Portal.AttachResponse.PullForce * Alpha;

			Portal.AttachResponse.ApplyAttachForce(Portal,
				Portal.RootComponent.AttachParent,
				Force);
		}
	}

	private void TickActiveSpecialcase(float DeltaTime)
	{
		int NumActiveGrabbed = Portal.GetNumActiveGrabbedComponents();
		if (NumActiveGrabbed == 0)
			return;

		// Debug::DrawDebugLine(Portal.OriginLocation, Portal.OriginLocation + Portal.ActorForwardVector * 400.0, FLinearColor::Blue, 5.0, 0.0, true);

		float CurrentAngle = Portal.TargetData.SceneComponent.WorldRotation.Yaw;
		float DeltaAngle = Math::Abs(CurrentAngle - LastAngle);
		LastAngle = CurrentAngle;
	
		// Apply force to all grabbed target components
		FVector AccumulatedOffset = FVector::ZeroVector;
		for (auto& Grab : Portal.Grabs)
		{
			// Ensure we have something to apply force to
			int NumTargets = Grab.TargetComponents.Num();
			if (NumTargets == 0 || !Grab.bHasTriggeredResponse)
				continue;

			for (auto TargetComponent : Grab.TargetComponents)
			{
				auto AffectedComponent = DarkPortal::GetParentForceAnchor(TargetComponent);
				FVector PullDirection = (Portal.OriginLocation - AffectedComponent.WorldLocation);

				if (Grab.ResponseComponent != nullptr)
				{
					FVector PortalOrigin = Grab.ResponseComponent.GetOriginLocationForPortal(Portal);
					PullDirection = (PortalOrigin - AffectedComponent.WorldLocation);
					FVector PointInFrontOfPortal = PortalOrigin + Portal.ActorForwardVector * 400.0;

					float PullForce = Grab.ResponseComponent.PullForce;
					if (DeltaAngle > KINDA_SMALL_NUMBER)
					{
						// Check if we're behind object? Then pull towards portal forward
						if (Math::DotToDegrees(Portal.ActorForwardVector.DotProduct(-PullDirection.GetSafeNormal())) > 45.0)
						{
							// find point in front of portal
							FVector Location = AffectedComponent.WorldLocation;
							Location.Z += 50.0;
							// Debug::DrawDebugString(Location, "Behind!!", FLinearColor::DPink, 0.0);
							PullDirection = (PointInFrontOfPortal - AffectedComponent.WorldLocation);// * Grab.ResponseComponent.PullForce;
							PullForce *= SpecialcaseMultiplyForce;
						}
					}
					float DistributedForce = PullForce / NumTargets;
					float Alpha = Math::Clamp(PullDirection.Size() / DarkPortal::Grab::ForceAlphaRadius, 0.0, 1.0);
					FVector Force = (PullDirection.GetSafeNormal() * DistributedForce * Alpha);

					Grab.ResponseComponent.ApplyGrabForce(Portal, TargetComponent, Force);
					Grab.ResponseComponent.ApplyGrabTargetLocation(Portal, TargetComponent, PortalOrigin, Portal.ActorForwardVector);
				}

				AccumulatedOffset += PullDirection;
			}
		}

		// Apply force to the attached actor towards the opposite direction
		//  magnitude comes from attached response component
		if (Portal.AttachResponse != nullptr)
		{
			float AverageDistance = AccumulatedOffset.Size() / NumActiveGrabbed;
			float Alpha = Math::Clamp(AverageDistance / DarkPortal::Grab::ForceAlphaRadius, 0.0, 1.0);
			float PullForce = Portal.AttachResponse.PullForce;
			if (DeltaAngle > KINDA_SMALL_NUMBER)
				PullForce *= SpecialcaseMultiplyForce;
			FVector Force = -AccumulatedOffset.GetSafeNormal() * PullForce * Alpha;

			Portal.AttachResponse.ApplyAttachForce(Portal,
				Portal.RootComponent.AttachParent,
				Force);
		}
	}
}