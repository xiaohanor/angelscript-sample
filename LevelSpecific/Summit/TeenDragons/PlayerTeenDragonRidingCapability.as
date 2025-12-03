
class UPlayerTeenDragonRidingCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerTeenDragonComponent DragonComp;

	UOtherPlayerIndicatorComponent IndicatorComp;
	UPlayerRespawnComponent RespawnComp;	
	UTeleportResponseComponent TeleportComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		TeleportComp = UTeleportResponseComponent::Get(Player);
		DragonComp.GetTeenDragon().AddActorDisable(this);
		TeleportComp.OnTeleported.AddUFunction(this, n"OnTeleported");
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
		UMovementSteppingSettings::SetSweepStep(Player, true, this, EHazeSettingsPriority::Sheet);
		UMovementSteppingSettings::SetBottomOfCapsuleMode(Player, ESteppingMovementBottomOfCapsuleMode::FlatExceptWhenGroundUnder, this, EHazeSettingsPriority::Sheet);
		Player.ApplySettings(DragonComp.GravitySettings, this, EHazeSettingsPriority::Gameplay);
		Player.ApplySettings(DragonComp.BlobShadowSettings, this, EHazeSettingsPriority::Gameplay);

		Player.ApplyCameraSettings(DragonComp.CameraSettings, 2, this, SubPriority = 40);
		DragonComp.GetTeenDragon().RemoveActorDisable(this);

		auto RenderingSettingsComp = UPlayerRenderingSettingsComponent::Get(Player);
		RenderingSettingsComp.AdditionalSubsurfaceMeshes.Add(DragonComp.DragonMesh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementSteppingSettings::ClearSweepStep(Player, this, EHazeSettingsPriority::Sheet);
		UMovementSteppingSettings::ClearBottomOfCapsuleMode(Player, this);

		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);

		DragonComp.GetTeenDragon().AddActorDisable(this);
	}

	
	UFUNCTION()
	private void OnTeleported()
	{
		Player.ApplyCameraSettings(DragonComp.CameraSettings, -1, this, SubPriority = 40);
	}
};