class USandHandAimCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(SandHand::Tags::SandHand);
	default CapabilityTags.Add(SandHand::Tags::SandHandAimCapability);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 110;

	USandHandPlayerComponent PlayerComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USandHandPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GetLevelStateHasTargets())
		{
			return true;
		}
		else
		{
			if(Player.IsAnyCapabilityActive(SandHand::Tags::SandHandMasterCapability))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GetLevelStateHasTargets())
		{
			return false;
		}
		else
		{
			if(Player.IsAnyCapabilityActive(SandHand::Tags::SandHandMasterCapability))
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AimComp.StartAiming(PlayerComp, PlayerComp.AimSettings);
		
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.ClearAimingRayOverride(this);
		AimComp.StopAiming(PlayerComp);

		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(PlayerComp.AimSpline != nullptr)
		{
			FAimingRay AimRay;
			AimRay.Origin = Player.ActorCenterLocation;
			const FTransform SplineTransform = PlayerComp.AimSpline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorLocation);
			const FVector RelativeLocation = SplineTransform.InverseTransformPositionNoScale(Player.ActorLocation);

			// When we go higher above the spline, start aiming slightly down instead of up
			const float HeightOverSpline = RelativeLocation.Z;
			const float HeightAlpha = Math::Saturate(Math::NormalizeToRange(HeightOverSpline, 0, 1000));
			const float AimAngle = Math::Lerp(-0.1, 0.1, HeightAlpha);

			const FVector ForwardVector = SplineTransform.Rotation.ForwardVector;
			const FVector AngledForwardVector = FQuat(SplineTransform.Rotation.RightVector, AimAngle) * ForwardVector;
			AimRay.Direction = AngledForwardVector;

			AimComp.ApplyAimingRayOverride(AimRay, this);
		}
	}

	bool GetLevelStateHasTargets() const
	{
		switch (Desert::GetDesertLevelState())
		{
			case EDesertLevelState::None:
				return true;

			case EDesertLevelState::Vortex:
				return true;

			default:
				return false;
		}
	}
};