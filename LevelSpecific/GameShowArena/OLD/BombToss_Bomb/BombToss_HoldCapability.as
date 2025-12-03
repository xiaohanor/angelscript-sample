class UBombTossHoldCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BombToss");
	default CapabilityTags.Add(n"BombTossHold");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 88;

	UBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerAimingComponent PlayerAimingComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UBombTossPlayerComponent::Get(Owner);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BombTossPlayerComponent.CurrentBombToss == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BombTossPlayerComponent.CurrentBombToss == nullptr)
			return true;

		if(BombTossPlayerComponent.CurrentBombToss.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BombTossPlayerComponent.CurrentBombToss.AttachToActor(Owner, n"RightAttach");
		BombTossPlayerComponent.CurrentBombToss.OnStartHolding.Broadcast(Player);
		BombTossPlayerComponent.BombTossBomb.BP_BombCaught();
		BombTossPlayerComponent.bHoldingBomb = true;

		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = true;
		AimSettings.OverrideAutoAimTarget = UBombTossTargetComponent;
		AimSettings.bApplyAimingSensitivity = false;
		PlayerAimingComponent.StartAiming(BombTossPlayerComponent, AimSettings);

		// Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		// Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		// Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		// Player.BlockCapabilities(PlayerMovementTags::Grapple, this);
		// Player.BlockCapabilities(PlayerMovementTags::LedgeGrab, this);
		// Player.BlockCapabilities(PlayerMovementTags::LedgeMantle, this);
		// Player.BlockCapabilities(PlayerMovementTags::LedgeMovement, this);
		// Player.BlockCapabilities(PlayerMovementTags::PoleClimb, this);
		// Player.BlockCapabilities(PlayerMovementTags::WallRun, this);
		// Player.BlockCapabilities(PlayerMovementTags::WallScramble, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(BombTossPlayerComponent.CurrentBombToss != nullptr)
		{
			BombTossPlayerComponent.CurrentBombToss.DetachFromActor();
			BombTossPlayerComponent.CurrentBombToss = nullptr;
		}

		PlayerAimingComponent.StopAiming(BombTossPlayerComponent);
		BombTossPlayerComponent.bHoldingBomb = false;

		// Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		// Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		// Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		// Player.UnblockCapabilities(PlayerMovementTags::Grapple, this);
		// Player.UnblockCapabilities(PlayerMovementTags::LedgeGrab, this);
		// Player.UnblockCapabilities(PlayerMovementTags::LedgeMantle, this);
		// Player.UnblockCapabilities(PlayerMovementTags::LedgeMovement, this);
		// Player.UnblockCapabilities(PlayerMovementTags::PoleClimb, this);
		// Player.UnblockCapabilities(PlayerMovementTags::WallRun, this);
		// Player.UnblockCapabilities(PlayerMovementTags::WallScramble, this);
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	
	}
}