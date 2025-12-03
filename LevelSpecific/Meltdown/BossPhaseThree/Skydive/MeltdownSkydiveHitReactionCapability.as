class UMeltdownSkydiveHitReactionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UMeltdownSkydiveComponent SkydiveComp;

	const float HitReactionDuration = 0.7;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMeltdownSkydiveHitReactionActivatedParams& Params) const
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
	void OnActivated(FMeltdownSkydiveHitReactionActivatedParams Params)
	{
		SkydiveComp.CurrentHitReactionRequest = 0;
		SkydiveComp.AnimData.HitReactionDirection = Params.RequestedHitReactionDirection;
		Player.BlockCapabilities(CapabilityTags::StickInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SkydiveComp.AnimData.HitReactionDirection = 0;
		Player.UnblockCapabilities(CapabilityTags::StickInput, this);
	}
}

struct FMeltdownSkydiveHitReactionActivatedParams
{
	int RequestedHitReactionDirection;
}