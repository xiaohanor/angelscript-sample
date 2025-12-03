class USketchbookBowAnimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 250;

	USketchbookBowPlayerComponent BowComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BowComp = USketchbookBowPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return BowComp.IsAiming();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !BowComp.IsAiming();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UpdateBowAttachment();

		Player.Mesh.SetAnimTrigger(n"RefreshPose");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Some values for animation
		const FAimingRay AimRay = BowComp.AimComp.GetPlayerAimingRay();

		const bool bWasAimingFwd = BowComp.AnimLocalAimDir.X > 0;
		BowComp.AnimLocalAimDir = Player.ActorTransform.InverseTransformVector(AimRay.Direction);
		const bool bIsAimingFwd = BowComp.AnimLocalAimDir.X > 0;

		if (bWasAimingFwd != bIsAimingFwd)
		{
			Player.Mesh.SetAnimTrigger(n"RefreshPose");
			UpdateBowAttachment();
		}
	}

	void UpdateBowAttachment()
	{
		const FName Socket = BowComp.AnimLocalAimDir.X > 0 ? n"LeftAttach" : n"RightAttach";
		BowComp.BowMeshComponent.AttachToComponent(Player.Mesh, Socket);
	}
};