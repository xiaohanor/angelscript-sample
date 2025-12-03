class UPlayerTeenDragonAttachmentCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 0;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default CapabilityTags.Add(n"TeenDragonAttachment");

	UPlayerTeenDragonComponent DragonComp;
	ATeenDragon TeenDragon;

	UOtherPlayerIndicatorComponent IndicatorComp;
	UPlayerRespawnComponent RespawnComp;	
	
	UPlayerVFXSettingsComponent VFXComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Owner);

		VFXComp = UPlayerVFXSettingsComponent::GetOrCreate(Player);

		TeenDragon = DragonComp.SpawnDragon(Player, DragonComp.TeenDragonClass);

		TeenDragon.PlayerAttachComponent.AttachToComponent(TeenDragon.Mesh, DragonComp.PlayerAttachSocket);
		TeenDragon.PlayerAttachComponent.SetRelativeTransform(DragonComp.PlayerAttachOffset);

		IndicatorComp = UOtherPlayerIndicatorComponent::Get(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		TeenDragon.DestroyActor();
		TeenDragon = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Don't activate if we are playing a cutscene immediately, wait until the cutscene is done
		if (TeenDragon.bIsControlledByCutscene)
			return false;

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
		TeenDragon.DetachFromActor();
		TeenDragon.AttachToComponent(Player.MeshOffsetComponent
			, NAME_None, EAttachmentRule::SnapToTarget
			, EAttachmentRule::SnapToTarget
			, EAttachmentRule::KeepWorld
			, true);
		
		Player.Mesh.AttachToComponent(TeenDragon.PlayerAttachComponent, AttachmentRule = EAttachmentRule::SnapToTarget);
	
		TeenDragon.CapsuleComponent.AddComponentCollisionBlocker(this);
		Player.CapsuleComponent.OverrideCapsuleSize(TeenDragon.CapsuleComponent.CapsuleRadius, TeenDragon.CapsuleComponent.CapsuleHalfHeight, this);
		TeenDragon.ActorRelativeLocation = FVector::ZeroVector;

		VFXComp.RelevantAttachMesh.Apply(TeenDragon.Mesh, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TeenDragon.CapsuleComponent.RemoveComponentCollisionBlocker(this);
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		TeenDragon.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.Mesh.AttachToComponent(Player.MeshOffsetComponent, AttachmentRule = EAttachmentRule::SnapToTarget);

		IndicatorComp.OverrideIndicatorLocation.Clear(this);

		VFXComp.RelevantAttachMesh.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector IndicatorLocation = TeenDragon.ActorLocation + TeenDragon.ActorUpVector * 200.0;
		IndicatorComp.OverrideIndicatorLocation.Apply(IndicatorLocation, this, EInstigatePriority::High);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		TeenDragon.Mesh.ResetAllAnimation();
	}
};