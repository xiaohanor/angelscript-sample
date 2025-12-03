class UGravityBladeGrappleCapability : UHazeCompoundCapability
{
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeWield);
	
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleGrapple);

	default CapabilityTags.Add(BlockedWhileIn::Ladder);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 95;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
			.Then(UGravityBladeGrappleThrowCapability())
			.Then(UGravityBladeGrappleTransitionCapability(GravityBladeGrapple::PullDelay))
			.Then(UGravityBladeGrapplePullCapability())
			.Then(UGravityBladeGrappleLandCapability())
			// TODO: Special attack when grapple target is enemy
		;
	}

	AHazePlayerCharacter Player;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeGrappleUserComponent GrappleComp;
	UPlayerTargetablesComponent TargetablesComp;

	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		BladeComp = UGravityBladeUserComponent::Get(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBladeGrappleData& TargetData) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!BladeComp.IsBladeEquipped())
			return false;

		if (!WasActionStarted(ActionNames::SecondaryLevelAbility))
			return false;

		if (!GrappleComp.AimGrappleData.IsValid())
			return false;

		if (GrappleComp.AimGrappleData.bIsCombatGrapple)
			return false;

		TargetData = GrappleComp.AimGrappleData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsAnyChildCapabilityActive())
			return true;

		if (Player.IsAnyCapabilityActive(GravityBladeGrappleTags::GravityBladeGrappleCamera))
			return false;

		if (!GrappleComp.ActiveGrappleData.IsValid())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FGravityBladeGrappleData& TargetData)
	{
		GrappleComp.ActiveGrappleData = TargetData;
		if (GrappleComp.TargetWidget != nullptr)
			GrappleComp.TargetWidget.BP_OnActivationAnimation();
		BladeComp.UnsheatheBlade();

		if (BladeComp.IsBladeEquipped())
			BladeComp.UnequipBlade();

		Player.BlockCapabilities(CapabilityTags::Death, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(GravityBladeTags::GravityBladeAim, this);

		Player.BlockCapabilities(GravityBladeCombatTags::GravityBladeCombat, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GrappleComp.ActiveGrappleData = FGravityBladeGrappleData();

		if (!BladeComp.IsBladeEquipped())
			BladeComp.EquipBlade(0.15);

		Player.UnblockCapabilities(CapabilityTags::Death, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(GravityBladeTags::GravityBladeAim, this);

		Player.UnblockCapabilities(GravityBladeCombatTags::GravityBladeCombat, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FTransform TargetTransform = GrappleComp.ActiveGrappleData.WorldTransform;
		const FVector TargetDirection = (TargetTransform.Location - Player.ActorCenterLocation).GetSafeNormal();
		const float VerticalAngle = GetConstrainedAngle(Player.ActorForwardVector, TargetDirection, Player.ActorRightVector);

		GrappleComp.AnimationData.GrappleVerticalAngle = Math::Clamp(VerticalAngle / 90.0, -1.0, 1.0);
	}

	float GetConstrainedAngle(const FVector& A,
		const FVector& B,
		const FVector& UpVector) const
	{
		const FVector ConstrainedA = A.ConstrainToPlane(UpVector).GetSafeNormal();
		const FVector ConstrainedB = B.ConstrainToPlane(UpVector).GetSafeNormal();

		float ConstrainedAngle = Math::RadiansToDegrees(
			ConstrainedA.AngularDistanceForNormals(ConstrainedB)
		);
		const FVector ACrossB = ConstrainedA.CrossProduct(ConstrainedB);

		if (ACrossB.DotProduct(UpVector) > 0.0)
			ConstrainedAngle *= -1.0;

		return ConstrainedAngle;
	}
}