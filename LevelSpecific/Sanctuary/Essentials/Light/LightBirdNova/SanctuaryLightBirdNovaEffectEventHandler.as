struct FLightBirdNovaParticlePerchEventData
{
	UPROPERTY(BlueprintReadOnly)
	ASanctuaryLightBirdNovaParticle Particle = nullptr;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player = nullptr;
}

class USanctuaryLightBirdNovaEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnNovaIlluminated() {}

	UFUNCTION(BlueprintEvent)
	void OnNovaDelluminated() {}

	UFUNCTION(BlueprintEvent)
	void OnPlayerStartPerchOnParticle(FLightBirdNovaParticlePerchEventData Data) {}

	UFUNCTION(BlueprintEvent)
	void OnPlayerStopPerchOnParticle(FLightBirdNovaParticlePerchEventData Data) {}
}