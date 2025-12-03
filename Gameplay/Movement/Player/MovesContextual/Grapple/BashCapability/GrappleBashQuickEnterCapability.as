class UPlayerGrappleBashQuickEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleEnter);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 5;
	default TickGroupSubPlacement = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UCameraPointOfInterest Poi;

	float Deceleration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		Poi = Player.CreatePointOfInterest();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGrappleBashQuickEnterActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (!WasActionStarted(ActionNames::Grapple))
			return false;

		if (Player.IsAnyCapabilityActive(PlayerGrappleTags::GrappleSlide))
			return false;

		auto PrimaryTarget = PlayerTargetablesComponent.GetPrimaryTarget(UGrappleBashPointComponent);
		if (PrimaryTarget == nullptr)
			return false;
		
		if (PrimaryTarget.GrappleType != EGrapplePointVariations::BashPoint)
			return false;

		if (PrimaryTarget.WorldLocation.Distance(Player.ActorLocation) > PrimaryTarget.Settings.QuickEnterDistance)
			return false;

		Params.SelectedGrapplePoint = PrimaryTarget;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGrappleBashQuickEnterActivationParams Params)
	{
		Player.BlockCapabilities(PlayerGrappleTags::GrappleEnter, this);

		Player.RootOffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.2);
		Player.SetActorLocation(Params.SelectedGrapplePoint.WorldLocation);

		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleBashAim;
		GrappleComp.Data.CurrentGrapplePoint = Params.SelectedGrapplePoint;
		GrappleComp.Data.CurrentGrapplePoint.ActivateGrapplePointForPlayer(Player);
		GrappleComp.Data.CurrentGrapplePoint.OnPlayerInitiatedGrappleToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);
		GrappleComp.Grapple.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerGrappleTags::GrappleEnter, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}
};

struct FGrappleBashQuickEnterActivationParams
{
	UGrapplePointBaseComponent SelectedGrapplePoint;
};