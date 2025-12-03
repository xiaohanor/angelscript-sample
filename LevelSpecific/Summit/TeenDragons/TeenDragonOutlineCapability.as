class UTeenDragonOutlineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Outline);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UPlayerTeenDragonComponent DragonComp;
	UStencilEffectViewerComponent OtherPlayerStencilComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		OtherPlayerStencilComp = UStencilEffectViewerComponent::Get(Player.OtherPlayer);
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
		Outline::AddToPlayerOutline(DragonComp.DragonMesh, Player, this, EInstigatePriority::Low);

		// Tell the stencil component where to trace to check if the player (that is, the dragon) is behind something
		FOutlinePlayerCoverageChecks DragonCoverage;
		DragonCoverage.OtherPlayerMesh = DragonComp.DragonMesh;
		DragonCoverage.CoverageBones.Add(n"Head");
		DragonCoverage.CoverageBones.Add(n"Neck1");
		DragonCoverage.CoverageBones.Add(n"Spine1");
		DragonCoverage.CoverageBones.Add(n"RightWingHand");
		DragonCoverage.CoverageBones.Add(n"LeftWingHand");
		DragonCoverage.CoverageBones.Add(n"RightHand");
		DragonCoverage.CoverageBones.Add(n"LeftHand");
		DragonCoverage.CoverageBones.Add(n"LeftFoot");
		DragonCoverage.CoverageBones.Add(n"RightFoot");
		DragonCoverage.CoverageBones.Add(n"Tail10");
		DragonCoverage.CoverageBones.Add(n"Tail5");
		DragonCoverage.CoverageBones.Add(n"Tail3");
		OtherPlayerStencilComp.PlayerCoverageCheckBones.Apply(DragonCoverage, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Outline::ClearOutline(DragonComp.DragonMesh, Player, this);
		OtherPlayerStencilComp.PlayerCoverageCheckBones.Clear(this);
	}
};