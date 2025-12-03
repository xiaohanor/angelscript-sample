asset DesertPlayerGrappleSettings of UPlayerGrappleSettings
{
	GrappleToPointAccelerationDuration = GrappleFishPlayer::GrappleToPointAccelerationDuration;
	GrappleToPointTopVelocity = GrappleFishPlayer::GrappleToPointTopVelocity;
}

class UDesertGrappleFishPlayerMountCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CameraTags::UsableWhileInDebugCamera);

	default TickGroup = EHazeTickGroup::Gameplay;
	UDesertGrappleFishPlayerComponent PlayerComp;
	UPlayerRespawnComponent RespawnComp;

	ADesertGrappleFish GrappleFish;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;

		if (PlayerComp.State != EDesertGrappleFishPlayerState::Grappling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerComp.State != EDesertGrappleFishPlayerState::Grappling)
			return true;

		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(DesertPlayerGrappleSettings, this, EHazeSettingsPriority::Script);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsWithAsset(DesertPlayerGrappleSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};