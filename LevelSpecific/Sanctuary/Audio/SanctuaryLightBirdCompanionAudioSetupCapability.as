class USanctuaryLightBirdCompanionAudioSetupCapability : UHazeCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto LightBirdCompanion = Cast<AAISanctuaryLightBirdCompanion>(Owner);
		EffectEvent::LinkActorToReceiveEffectEventsFrom(Game::GetMio(), LightBirdCompanion);

		auto AudioComponent = UHazeAudioComponent::GetOrCreate(LightBirdCompanion, n"LightBirdCompanion_AudioComponent");
		auto VOEmitter = AudioComponent.GetEmitter(LightBirdCompanion, n"LightBirdCompanion_VOEmitter");
		VOEmitter.SetAttenuationScaling(15000);
		AudioComponent.AttachTo(LightBirdCompanion.Mesh, AttachType = EAttachLocation::SnapToTarget);
	}	
}