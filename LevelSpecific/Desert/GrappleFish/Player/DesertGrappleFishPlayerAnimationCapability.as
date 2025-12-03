class UDesertGrappleFishPlayerAnimationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UDesertGrappleFishPlayerComponent PlayerComp;

	bool bHasGrappledAfterDetach;

	UPlayerGrappleComponent GrappleComp;
	bool bGrappleWasActive;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;

		if (bHasGrappledAfterDetach)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return true;

		if (bHasGrappledAfterDetach)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.AddLocomotionFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.RemoveLocomotionFeature(this);
		Player.Mesh.AttachToComponent(Player.MeshOffsetComponent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bIsGrappleActive = GrappleComp.IsGrappleActive();
		if (!bIsGrappleActive && bGrappleWasActive && PlayerComp.bShouldDetachFromShark)
		{
			bHasGrappledAfterDetach = true;
			return;
		}

		bGrappleWasActive = bIsGrappleActive;
		if (bIsGrappleActive)
			return;

		if (PlayerComp.State == EDesertGrappleFishPlayerState::Riding || PlayerComp.State == EDesertGrappleFishPlayerState::FinalJump || Player.IsCapabilityTagBlocked(PlayerMovementTags::AirJump))
			PlayerComp.RequestLocomotion(this);
		//if (PlayerComp.State == EDesertGrappleFishPlayerState::Riding || Player.IsCapabilityTagBlocked(PlayerMovementTags::AirJump))
	}
};