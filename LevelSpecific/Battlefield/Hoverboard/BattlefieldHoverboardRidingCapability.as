class UBattlefieldHoverboardRidingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BattlefieldHoverboard");

	default DebugCategory = n"Hoverboard";
	default TickGroup = EHazeTickGroup::Input;

	ABattlefieldHoverboard Hoverboard;
	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UTeleportResponseComponent TeleportComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		Hoverboard = SpawnActor(HoverboardComp.HoverboardClass, bDeferredSpawn = true);
		Hoverboard.Player = Player;
		Hoverboard.HoverboardComp = HoverboardComp;

		HoverboardComp.Hoverboard = Hoverboard;
		HoverboardComp.Player = Player;
		FinishSpawningActor(Hoverboard);
		Hoverboard.AttachToActor(Player, HoverboardComp.AttachmentSocketName);

		Hoverboard.AddActorTickBlock(this);
		Hoverboard.AddActorVisualsBlock(this);
		HoverboardComp.ToggleHoverboard(false);

		TeleportComp = UTeleportResponseComponent::GetOrCreate(Player);
		TeleportComp.OnTeleported.AddUFunction(this, n"OnPlayerTeleported");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerTeleported()
	{
		HoverboardComp.ResetWantedRotationToCurrentRotation();
		HoverboardComp.SetCameraWantedRotationToWantedRotation();
		HoverboardComp.AccRotation.SnapTo(HoverboardComp.WantedRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Hoverboard.DestroyActor();
		Hoverboard = nullptr;
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
		HoverboardComp.ToggleHoverboard(true);
		Hoverboard.RemoveActorTickBlock(this);
		Hoverboard.RemoveActorVisualsBlock(this);

		MoveComp.ApplyMovementImpactsReturnPhysMats(true, this);

		Player.CapsuleComponent.OverrideCapsuleSize(Hoverboard.Collision.CapsuleRadius, Hoverboard.Collision.CapsuleHalfHeight
			,this, EInstigatePriority::Interaction);

		Outline::AddToPlayerOutline(Hoverboard.Mesh, Player, this, EInstigatePriority::Normal);

		Player.ApplySettings(HoverboardComp.GravitySettings, this);
		Player.ApplySettings(HoverboardComp.SteppingSettings, this);
		Player.ApplySettings(HoverboardComp.MovementStandardSettings, this);

		Player.ApplyCameraSettings(HoverboardComp.RidingCameraSettings, HoverboardComp.CameraControlSettings.SettingsBlendTime, this, EHazeCameraPriority::Low);

		Player.SetActorVelocity(Player.ActorForwardVector * UBattlefieldHoverboardGroundMovementSettings::GetSettings(Player).MinSpeed);

		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		Player.BlockCapabilities(CameraTags::CameraOptionalChaseAssistance, this);

		HoverboardComp.ResetWantedRotationToCurrentRotation();
		HoverboardComp.SetCameraWantedRotationToWantedRotation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HoverboardComp.ToggleHoverboard(false);
		Hoverboard.AddActorTickBlock(this);
		Hoverboard.AddActorVisualsBlock(this);

		MoveComp.ClearMovementImpactsReturnPhysMats(this);

		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		Outline::ClearOutlineOnActor(Hoverboard, Player, this);

		Player.ClearSettingsByInstigator(this);

		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
		Player.UnblockCapabilities(CameraTags::CameraOptionalChaseAssistance, this);
	}
};