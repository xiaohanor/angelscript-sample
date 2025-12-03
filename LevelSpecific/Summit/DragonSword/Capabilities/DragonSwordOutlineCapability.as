class UDragonSwordOutlineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Outline);

	default TickGroup = EHazeTickGroup::Gameplay;
	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	UDragonSwordUserComponent SwordComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UDragonSwordUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwordComp.SwordIsActive())
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwordComp.SwordIsActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// The outline asset is normally only applied to one player during fullscreen, but we want to see both
		auto OutlineAsset = Outline::GetPlayerOutlineAsset(Player.OtherPlayer);
		Outline::ApplyOutlineOnActor(Player, Game::GetZoe(), OutlineAsset, this, EInstigatePriority::Normal);
		Outline::ApplyOutlineOnActor(SwordComp.Weapon, Game::GetZoe(), OutlineAsset, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Outline::ClearOutlineOnActor(Player, Game::GetZoe(), this);
		Outline::ClearOutlineOnActor(SwordComp.Weapon, Game::GetZoe(), this);
	}
};