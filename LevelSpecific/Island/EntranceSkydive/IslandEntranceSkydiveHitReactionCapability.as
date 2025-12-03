class UIslandEntranceSkydiveHitReactionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandEntranceSkydiveComponent SkydiveComp;

	const float HitReactionDuration = 0.7;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandEntranceSkydiveHitReactionActivatedParams& Params) const
	{
		if(SkydiveComp.CurrentHitReactionRequest == 0)
			return false;

		Params.RequestedHitReactionDirection = SkydiveComp.CurrentHitReactionRequest;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > HitReactionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandEntranceSkydiveHitReactionActivatedParams Params)
	{
		SkydiveComp.CurrentHitReactionRequest = 0;
		SkydiveComp.AnimData.HitReactionDirection = Params.RequestedHitReactionDirection;
		Player.PlayCameraShake(SkydiveComp.CameraShake, this);
		Player.PlayForceFeedback(SkydiveComp.ImpactFF, false, false, this);
		Player.BlockCapabilities(CapabilityTags::StickInput, this);
		Player.DamagePlayerHealth(0.1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SkydiveComp.AnimData.HitReactionDirection = 0;
		Player.UnblockCapabilities(CapabilityTags::StickInput, this);
	}
}

struct FIslandEntranceSkydiveHitReactionActivatedParams
{
	int RequestedHitReactionDirection;
}