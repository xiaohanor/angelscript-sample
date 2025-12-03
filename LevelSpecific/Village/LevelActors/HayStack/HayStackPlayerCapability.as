struct FHayStackActivationParams
{
	AHayStack HayStack;
}

class UHayStackPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	UHayStackPlayerComponent HayStackPlayerComp;
	UHazeMovementComponent MoveComp;

	bool bExitWithMovementInput = false;
	AHayStack HayStack;

	bool bVisibilityBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HayStackPlayerComp = UHayStackPlayerComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHayStackActivationParams& Params) const
	{
		if (HayStackPlayerComp.CurrentHayStack == nullptr)
			return false;

		Params.HayStack = HayStackPlayerComp.CurrentHayStack;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HayStackPlayerComp.CurrentHayStack == nullptr)
			return true;

		if (WasActionStarted(ActionNames::Cancel))
			return true;

		if (WasActionStarted(ActionNames::MovementJump))
			return true;

		if (bExitWithMovementInput)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHayStackActivationParams Params)
	{
		bVisibilityBlocked = false;
		bExitWithMovementInput = false;
		HayStack = Params.HayStack;

		if (!Player.IsAnyCapabilityActive(n"HayStackDive"))
			Player.SmoothTeleportActor(HayStack.PlayerLocationComp.WorldLocation, Player.ActorRotation, this, 0.2);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Outline, this);

		Player.ResetMovement();

		Player.ApplyCameraSettings(HayStack.CamSettings, 1.0, this);

		Timer::SetTimer(this, n"BlockVisibility", 0.25);
	}

	UFUNCTION()
	private void BlockVisibility()
	{
		if (!IsActive())
			return;

		if (bVisibilityBlocked)
			return;

		Player.BlockCapabilities(CapabilityTags::Visibility, this);
		bVisibilityBlocked = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Outline, this);

		if (bVisibilityBlocked)
			Player.UnblockCapabilities(CapabilityTags::Visibility, this);

		FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		FVector MoveInputXY = FVector(MoveInput.Y, MoveInput.X, 0);
		FVector Forward = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		FRotator Rotation = FRotator::MakeFromX(Forward);
		FVector ExitDir = Rotation.RotateVector(MoveInputXY);

		if (MoveInput.Equals(FVector2D::ZeroVector))
			ExitDir = Forward;

		if (IsValid(HayStack))
		{
			Player.TeleportActor(HayStack.PlayerLocationComp.WorldLocation, ExitDir.Rotation(), this, false);
			HayStack.Exit(Player);
		}

		Player.AddMovementImpulse(ExitDir * 600.0 + (FVector::UpVector * 1000.0));
		HayStackPlayerComp.CurrentHayStack = nullptr;

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration <= 0.5)
			return;

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		if (Input.Size() > 0.0)
			bExitWithMovementInput = true;
	}
}