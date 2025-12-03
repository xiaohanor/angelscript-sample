struct FDarkPortalPlayerFireParams
{
	FDarkPortalTargetData TargetData;
}

class UDarkPortalPlayerFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalFire);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UDarkPortalUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkPortalUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDarkPortalPlayerFireParams& Params) const
	{
		if (!AimComp.IsAiming(UserComp))
			return false;

		if (TargetablesComp.TargetingMode.Get() != EPlayerTargetingMode::SideScroller)
		{
			if (!WasActionStopped(ActionNames::PrimaryLevelAbility))
				return false;
		}
		else
		{
			if (!UserComp.AimTargetData.IsValid())
				return false;

			if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
				return false;
		}

		Params.TargetData = UserComp.AimTargetData;
		if (Params.TargetData.SceneComponent != nullptr)
		{
			// If there is an auto-placement component, make sure the portal gets placed there
			TArray<UDarkPortalAutoPlacementComponent> AllPlacementComps;
			Params.TargetData.SceneComponent.Owner.GetComponentsByClass(AllPlacementComps);

			for (UDarkPortalAutoPlacementComponent PlacementComp : AllPlacementComps)
			{
				if (PlacementComp.bOnlyWhenPlacedInShape)
				{
					if (!PlacementComp.PlacementShape.IsPointInside(PlacementComp.WorldTransform, Params.TargetData.WorldLocation))
						continue;
				}

				if (PlacementComp.ForwardVector.AngularDistance(Params.TargetData.WorldNormal) > Math::DegreesToRadians(PlacementComp.MaximumAutoPlacementSurfaceAngle))
					continue;

				FTransform TargetTransform = Params.TargetData.SceneComponent.GetSocketTransform(Params.TargetData.SocketName);
				Params.TargetData.RelativeLocation = TargetTransform.InverseTransformPositionNoScale(PlacementComp.WorldLocation);
				Params.TargetData.RelativeNormal = TargetTransform.InverseTransformVector(PlacementComp.ForwardVector);
				Params.TargetData.bSpecialCasePullBecauseTargetCanRotate = PlacementComp.bSpecialCasePullBecauseActorCanRotate;
				break;
			}
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDarkPortalPlayerFireParams Params)
	{
		if (!Portal.IsAbsorbed())
			Portal.InstantRecall();

		Portal.Fire(Params.TargetData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	ADarkPortalActor GetPortal() const property
	{
		return UserComp.Portal;
	}
}