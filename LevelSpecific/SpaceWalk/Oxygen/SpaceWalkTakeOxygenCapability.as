class USpaceWalkTakeOxygenCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;

	USpaceWalkOxygenPlayerComponent OxyComp;
	USpaceWalkOxygenSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OxyComp = USpaceWalkOxygenPlayerComponent::Get(Player);
		Settings = USpaceWalkOxygenSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (IsValid(OxyComp.OxygenInteraction))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsValid(OxyComp.OxygenInteraction))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.SetActorVelocity(FVector::ZeroVector);

		USceneComponent TargetPoint;
		if (Player.IsMio())
			TargetPoint = OxyComp.OxygenInteraction.MioLocation;
		else
			TargetPoint = OxyComp.OxygenInteraction.ZoeLocation;

		Player.SmoothTeleportActor(TargetPoint.WorldLocation, TargetPoint.WorldRotation, this, 0.4);
		Player.AttachToComponent(TargetPoint, AttachmentRule = EAttachmentRule::SnapToTarget);

		OxyComp.OxygenInteraction.IsReadyToInteract[Player] = true;
		OxyComp.bTouchScreenGrounded = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DetachRootComponentFromParent();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.SetActorVelocity(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!IsValid(OxyComp.OxygenInteraction))
			return;

		if (OxyComp.OxygenInteraction.AreBothPlayersReadyToInteract() && OxyComp.OxygenInteraction.bPumpingStarted
			&& OxyComp.OxygenInteraction.ActivePlayer == Player
			&& HasControl()
			&& !OxyComp.bHasRunOutOfOxygen)
		{
			if (WasActionStarted(ActionNames::Interaction))
			{
				OxyComp.OxygenInteraction.Pump();
			}
		}

		if (Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"SpaceTouchScreen", this);
	}
};