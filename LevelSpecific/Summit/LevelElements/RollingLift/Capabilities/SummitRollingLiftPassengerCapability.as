class USummitRollingLiftPassengerCapability : UHazePlayerCapability
{
	// Need this so we start after the interaction is finished
	default CapabilityTags.Add(n"InteractionCancel");

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	USummitTeenDragonRollingLiftComponent LiftComp;
	UPlayerAimingComponent AimComp;
	UPlayerAcidTeenDragonComponent DragonComp;
	ASummitRollingLift CurrentRollingLift;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);

		CurrentRollingLift = LiftComp.CurrentRollingLift;
		Player.AttachRootComponentTo(CurrentRollingLift.PlatformPasengerRoot, NAME_None, EAttachLocation::SnapToTarget);

		FAimingSettings Settings;
		Settings.bShowCrosshair = true;
		Settings.bUseAutoAim = true;
		AimComp.StartAiming(DragonComp, Settings);

		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(DragonComp);

		Player.DetachRootComponentFromParent();
		LiftComp.CurrentRollingLift = nullptr;

		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator ViewRotation = Player.GetViewRotation();
		FRotator MovementOrientation = FRotator::MakeFromZX(FVector::UpVector, ViewRotation.ForwardVector);
		//MovementOrientation = Math::RInterpTo(Player.ActorRotation, MovementOrientation, DeltaTime, 5); // If we want, but it looks laggy
		Player.SetActorRotation(MovementOrientation);
		CurrentRollingLift.PlatformRoot.SetWorldRotation(MovementOrientation);
		DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::Movement);
	}
};