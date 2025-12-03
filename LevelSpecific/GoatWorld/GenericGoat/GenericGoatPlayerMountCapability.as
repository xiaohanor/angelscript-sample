class UGenericGoatPlayerMountCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UGenericGoatPlayerComponent GoatComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GoatComp = UGenericGoatPlayerComponent::Get(Player);
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
		Player.PlaySlotAnimation(Animation = GoatComp.MountAnim, bLoop = true);

		Player.MeshOffsetComponent.SetRelativeLocation(FVector(-60.0, 0.0, 75.0));

		Player.ApplyCameraSettings(GoatComp.CamSettings, 0.0, this, EHazeCameraPriority::Low);

		Player.CapsuleComponent.OverrideCapsuleRadius(60.0, this);

		FHitResult DummyHit;
		GoatComp.CurrentGoat.SetActorRelativeLocation(FVector(60.0, 0.0, -75.0), false, DummyHit, false);

		Player.Mesh.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.Mesh.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}