class UPlayerAudioReflectionTraceFullscreenCapability : UPlayerAudioReflectionTraceCapability
{
	default CapabilityTags.Remove(Audio::Tags::DefaultReflectionTracing);
	default CapabilityTags.Remove(Audio::Tags::LevelSpecificTracingBlocking);
	default CapabilityTags.Add(Audio::Tags::FullscreenReflectionTracing);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

   	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return !Player.bIsParticipatingInCutscene && SceneView::IsFullScreen();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Player.bIsParticipatingInCutscene || !SceneView::IsFullScreen();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(Audio::Tags::DefaultReflectionTracing, this);
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Audio::Tags::DefaultReflectionTracing, this);
		Super::OnDeactivated();
	}

	// Only difference is it uses the player rotation instead. This might change.
	FVector GetDirection(int DirectionIndex) override
	{
		if (DirectionIndex == 0)
		{
			auto WorldUp = ReflectionComponent.GetWorldUp();
			// Pretend it's world right ...
			auto WorldRight = Player.ActorRightVector;
			auto ForwardVector = WorldRight.CrossProduct(WorldUp);

			if (ForwardVector != LastForwardVector)
			{
				LastForwardVector = ForwardVector;
				SetupTraceDirections(ForwardVector, WorldUp, WorldRight);
			}

			return GetUpwardsDirection(WorldUp, WorldRight);
		}

		return TraceDirections[DirectionIndex];
	}
}