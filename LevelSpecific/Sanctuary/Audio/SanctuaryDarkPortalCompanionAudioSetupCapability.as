class USanctuaryDarkPortalCompanionAudioSetupCapability : UHazeCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto DarkPortalCompanion = Cast<AAISanctuaryDarkPortalCompanion>(Owner);
		EffectEvent::LinkActorToReceiveEffectEventsFrom(Game::GetZoe(), DarkPortalCompanion);

		auto AudioComponent = UHazeAudioComponent::GetOrCreate(DarkPortalCompanion, n"DarkPortalCompanion_AudioComponent");
		auto VOEmitter = AudioComponent.GetEmitter(DarkPortalCompanion, n"DarkPortalCompanion_VOEmitter");
		VOEmitter.SetAttenuationScaling(15000);
		AudioComponent.AttachTo(DarkPortalCompanion.Mesh, AttachType = EAttachLocation::SnapToTarget);
	}	
}