class UGameShowArenaBombAttachmentPlateCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGameShowArenaBombAttachmentPlate AttachmentPlate;
	UGameShowArenaBombAttachmentPlatePlayerComponent AttachmentPlateComp;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		// AttachmentPlateComp = UGameShowArenaBombAttachmentPlatePlayerComponent::Get(Player);
		// AttachmentPlate = SpawnActor(AttachmentPlateComp.AttachmentPlateClass, bDeferredSpawn = true);
		// AttachmentPlateComp.AttachmentPlate = AttachmentPlate;
		// FinishSpawningActor(AttachmentPlate);

		// AttachmentPlate.AttachToActor(Player, AttachmentPlateComp.AttachmentBone);
		// AttachmentPlate.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttachmentPlate.RemoveActorDisable(this);
		Outline::AddToPlayerOutlineActor(AttachmentPlate, Player, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AttachmentPlate.AddActorDisable(this);
		Outline::RemoveFromPlayerOutlineActor(AttachmentPlate, Player, this);
	}
};