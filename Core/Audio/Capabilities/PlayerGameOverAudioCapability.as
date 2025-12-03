class UPlayerGameOverAudioCapability : UHazePlayerCapability
{
	UPlayerHealthComponent HealthComp;

	const FHazeAudioID GameOverRtpc = FHazeAudioID("Rtpc_Global_IsGameOver");

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return HealthComp.bIsGameOver;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !HealthComp.bIsGameOver;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AudioComponent::SetGlobalRTPC(GameOverRtpc, 1.0, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{			
		AudioComponent::SetGlobalRTPC(GameOverRtpc, 0.0, 0);
	}
}