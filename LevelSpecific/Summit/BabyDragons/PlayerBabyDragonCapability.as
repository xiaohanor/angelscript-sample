
class UPlayerBabyDragonCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default CapabilityTags.Add(BabyDragon::BabyDragon);

	UPlayerBabyDragonComponent DragonComp;
	UPlayerRenderingSettingsComponent RenderingSettings;
	ABabyDragon BabyDragon;

	UPlayerRespawnComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerBabyDragonComponent::Get(Owner);
		RenderingSettings = UPlayerRenderingSettingsComponent::GetOrCreate(Owner);

		RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (DragonComp.BabyDragon == nullptr)
		{
			DragonComp.SpawnBabyDragon(Player);
		}

		BabyDragon = DragonComp.BabyDragon;
		DragonComp.AttachBabyDragon(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RenderingSettings.AdditionalSubsurfaceMeshes.Remove(BabyDragon.Mesh);

		BabyDragon.DestroyActor();
		BabyDragon = nullptr;
		DragonComp.BabyDragon = nullptr;
	}

	UFUNCTION()
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		BabyDragon.Mesh.ResetAllAnimation();
	}
};