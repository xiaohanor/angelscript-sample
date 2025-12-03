class UPlayerAdultDragonRidingCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAdultDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	UTeleportResponseComponent TeleportComp;
	UCameraUserComponent CameraUserComp;
	UPlayerRespawnComponent RespawnComp;

	AAdultDragon AdultDragon;

	UPlayerVFXSettingsComponent VFXComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		TeleportComp = UTeleportResponseComponent::GetOrCreate(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);

		AdultDragon = DragonComp.SpawnDragon(Player, DragonComp.AdultDragonClass);
		AdultDragon.AddActorDisable(this);

		TeleportComp.OnTeleported.AddUFunction(this, n"OnPlayerTeleported");
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");

		VFXComp = UPlayerVFXSettingsComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		AdultDragon.DestroyActor();
		AdultDragon = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Outline::AddToPlayerOutline(AdultDragon.Mesh, Player, this, EInstigatePriority::Low);

		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		
		Player.CapsuleComponent.OverrideCapsuleSize(AdultDragon.CapsuleComponent.CapsuleRadius, AdultDragon.CapsuleComponent.CapsuleHalfHeight, this);
		
		if (AdultDragon.bDelayAttachmentInRidingCapability == false)
		{
			Player.MeshOffsetComponent.AttachToComponent(AdultDragon.Mesh, n"None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepRelative, true);
			Player.MeshOffsetComponent.SnapToRelativeTransform(this, AdultDragon.AttachComp, FTransform::Identity);
			Player.MeshOffsetComponent.SetWorldScale3D(FVector(1.0, 1.0, 1.0));
		}
		
		Player.ApplyCameraSettings(DragonComp.CameraSettings, 0, this, EHazeCameraPriority::Low, SubPriority = 61);

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this, EInstigatePriority::Normal);
		
		AdultDragon.RemoveActorDisable(this);

		// Flight Mode can be overriden from level blueprint begin play which runs first
		if(DragonComp.FlightMode == EAdultDragonFlightMode::NotSet)
			DragonComp.SetFlightMode(EAdultDragonFlightMode::Flying);		
		
		DragonComp.AccRotation.SnapTo(CameraUserComp.ViewRotation);
		DragonComp.WantedRotation = CameraUserComp.ViewRotation;

		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		VFXComp.RelevantAttachMesh.Apply(AdultDragon.Mesh, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Outline::ClearOutlineOnActor(AdultDragon, Player, this);
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);

		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		Player.ClearCameraSettingsByInstigator(this);
		Player.GetMeshOffsetComponent().ClearOffset(this);
		Player.MeshOffsetComponent.AttachToComponent(Player.RootOffsetComponent, n"None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepRelative, true);
		Player.MeshOffsetComponent.SetRelativeTransform(FTransform::Identity);
		Player.MeshOffsetComponent.SetWorldScale3D(FVector(1.0, 1.0, 1.0));

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		
		TeleportComp.OnTeleported.UnbindObject(this);
		AdultDragon.AddActorDisable(this);

		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		VFXComp.RelevantAttachMesh.Clear(this);
	}

	UFUNCTION()
	private void OnPlayerTeleported()
	{
		DragonComp.AccRotation.SnapTo(Player.ActorRotation);
		DragonComp.WantedRotation = Player.ActorRotation;
	}

	UFUNCTION()
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		AdultDragon.Mesh.ResetAllAnimation();
	}
};