class UIslandJetpackAttachmentCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Jetpack");

	default DebugCategory = n"Jetpack";

	default TickGroup = EHazeTickGroup::AfterGameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AIslandJetpack Jetpack;

	UIslandJetpackComponent JetpackComp;

	UIslandJetpackSettings JetpackSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Player);

		JetpackSettings = UIslandJetpackSettings::GetSettings(Player);
		Jetpack = SpawnActor(JetpackSettings.JetpackClass, bDeferredSpawn = true);
		Jetpack.Player = Player;
		Jetpack.JetpackMesh.SkeletalMeshAsset = Player.IsMio() ? JetpackSettings.MioMesh : JetpackSettings.ZoeMesh;
		JetpackComp.Jetpack = Jetpack;
		FinishSpawningActor(Jetpack);

		Jetpack.AddActorDisable(this);
		Jetpack.AttachToActor(Player, JetpackSettings.AttachmentBone
			, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Jetpack.DestroyActor();
		Jetpack = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!JetpackComp.IsOn())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!JetpackComp.IsOn())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Jetpack.RemoveActorDisable(this);

		Outline::AddToPlayerOutlineActor(Jetpack, Player, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Jetpack.AddActorDisable(this);

		Outline::ClearOutlineOnActor(Jetpack, Player, this);
	}
};