class UGravityBladeGrappleEjectCapability : UHazeCompoundCapability
{
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleEject);
	default BlockExclusionTags.Add(GravityBladeGrappleTags::GravityBladeGrappleEject);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 96;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
			.Then(UGravityBladeGrappleEjectJumpCapability())
			.Then(UGravityBladeGrappleEjectSlowAimCapability())
			.Then(UGravityBladeGrappleEjectDropCapability())
		;
	}

	AHazePlayerCharacter Player;
	UGravityBladeGrappleUserComponent GrappleComp;
	UCameraUserComponent CameraUserComp;
	UPlayerMovementComponent MoveComp;
	UGravityBladeGrappleEjectComponent EjectComp;

	float ActivateTime;

	private bool bIsGravityAlignedThisFrame = false;
	private bool bWasGravityAlignedLastFrame = false;

	FQuat InitialWorldUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		CameraUserComp = UCameraUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		EjectComp = UGravityBladeGrappleEjectComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bWasGravityAlignedLastFrame = bIsGravityAlignedThisFrame;
		bIsGravityAlignedThisFrame = GrappleComp.ActiveAlignSurface.IsValid();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!bWasGravityAlignedLastFrame)
			return false;

		if(bIsGravityAlignedThisFrame)
			return false;

		if(GrappleComp.ActiveAlignSurface.ShiftComponent == nullptr)
			return false;

		if(!GrappleComp.ActiveAlignSurface.ShiftComponent.bEjectPlayer)
			return false;

		if(GrappleComp.ActiveGrappleData.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > 0.5)
		{
			if(MoveComp.HasAnyValidBlockingContacts())
				return true;
		}

		if(GrappleComp.ActiveGrappleData.IsValid())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool PostChildrenShouldDeactivate() const
	{
		if(!IsAnyChildCapabilityActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialWorldUp = FQuat::MakeFromZ(-Player.GetGravityDirection());
		ActivateTime = Time::GameTimeSeconds;

		Player.BlockCapabilities(GravityBladeCombatTags::GravityBladeCombat, GravityBladeGrapple::Eject::Instigator);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, GravityBladeGrapple::Eject::Instigator);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, GravityBladeGrapple::Eject::Instigator);
		EjectComp.EjectData = GrappleComp.ActiveAlignSurface.ShiftComponent.EjectData;
		
		MoveComp.ClearCurrentGroundedState();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearActorTimeDilation(GravityBladeGrapple::Eject::Instigator);
		Player.ClearCameraSettingsByInstigator(GravityBladeGrapple::Eject::Instigator);
		Player.StopSlotAnimationByAsset(GrappleComp.GrappleEjectAnimation);
		Player.ClearGravityDirectionOverride(Skyline::GravityProxy);

		Player.UnblockCapabilities(GravityBladeCombatTags::GravityBladeCombat, GravityBladeGrapple::Eject::Instigator);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, GravityBladeGrapple::Eject::Instigator);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, GravityBladeGrapple::Eject::Instigator);

		EjectComp.OnEjectComplete.Broadcast();
		
		ResetCompoundNodes();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Alpha = Math::Saturate(ActualActiveDuration / 3);

		const FQuat WorldUpRotation = FQuat::Slerp(InitialWorldUp, FQuat::MakeFromZ(FVector::UpVector), Alpha);
		const FRotator DesiredRotation = CameraUserComp.GetDesiredRotation();
		const FVector DesiredForward = DesiredRotation.ForwardVector;
		const FRotator NewRotation = FRotator::MakeFromXZ(DesiredForward, WorldUpRotation.UpVector);
		CameraUserComp.SetDesiredRotation(NewRotation, GravityBladeGrapple::Eject::Instigator);
	}

	float GetActualActiveDuration() const property
	{
		return Time::GameTimeSeconds - ActivateTime;
	}
}