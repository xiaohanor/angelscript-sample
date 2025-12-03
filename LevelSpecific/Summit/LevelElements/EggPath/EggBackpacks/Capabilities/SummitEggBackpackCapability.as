class USummitEggBackpackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(EggBackpackCapabilityTags::EggBackpack);
	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default DebugCategory = SummitDebugCapabilityTags::EggBackpack;

	ASummitEggBackpack Backpack;
	USummitEggBackpackComponent BackpackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BackpackComp = USummitEggBackpackComponent::Get(Player);
		BackpackComp.Player = Player;

		Backpack = SpawnActor(BackpackComp.BackpackClass, bDeferredSpawn = true);
		BackpackComp.Backpack = Backpack;

		FinishSpawningActor(Backpack);
		Backpack.AttachToActor(Player, BackpackComp.AttachmentSocketName, EAttachmentRule::SnapToTarget);
		Backpack.AddActorDisable(this);
		Backpack.SetupSoundDef();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Backpack.DestroyActor();
		Backpack = nullptr;
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
		Outline::AddToPlayerOutlineActor(Backpack, Player, this, EInstigatePriority::Normal);
		Backpack.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Outline::RemoveFromPlayerOutlineActor(Backpack, Player, this);
		Backpack.AddActorDisable(this);
	}
};