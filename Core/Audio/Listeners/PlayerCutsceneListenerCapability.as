
class UPlayerCutsceneListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::CutsceneListener);
	default TickGroup = Audio::ListenerTickGroup;

	UHazeAudioListenerComponent Listener;
	AHazePlayerCharacter OtherPlayer;
	AHazeLevelSequenceActor LevelSequenceActor;
	UCameraUserComponent User;

	bool bStartedBlendOut = false;
	bool bBlockedReflection = false;

	float PreviousSizePercentage;
	float StartTimeForBlend = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OtherPlayer = Player.GetOtherPlayer();
		Listener = UHazeAudioListenerComponent::Get(Player);
		User = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Player.bIsParticipatingInCutscene;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !Player.bIsParticipatingInCutscene;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block the default listener
		Player.BlockCapabilities(Audio::Tags::Listener, this);

		// Block certain capabilities depending on which type of cutscene
		LevelSequenceActor = Player.GetActiveLevelSequenceActor();
		if (LevelSequenceActor != nullptr && LevelSequenceActor.bIsCutscene) 
		{
			bBlockedReflection = true;
			Player.BlockCapabilities(Audio::Tags::ReflectionTracing, this);
		}
			
		bStartedBlendOut = false;
		PreviousSizePercentage = -1;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Audio::Tags::Listener, this);
		if (bBlockedReflection)
		{
			bBlockedReflection = false;
			Player.UnblockCapabilities(Audio::Tags::ReflectionTracing, this);
		}
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
	{
		// If reloading during load the LevelSequenceActor reference can be lost.
		if (LevelSequenceActor == nullptr) 
		{
			LevelSequenceActor = Player.GetActiveLevelSequenceActor();
			devCheck(LevelSequenceActor != nullptr);
		}

		// 1. During cutscene update listener to camera, if needed (i.e is camera is used in cutscene).
		// 2. When cutscene is ending and camera is starting to blendout, shift to both listeners lerping to their usual position.
		UHazeCameraComponent Camera = Player.GetCurrentlyUsedCamera();
		float SizePercentage = SceneView::GetPlayerViewSizePercentage(Player);
		bool hasChanged = PreviousSizePercentage != SizePercentage;
		PreviousSizePercentage = SizePercentage;
		
		if (SizePercentage == 0.5) 
		{
			float TimeLeft = LevelSequenceActor.GetTimeRemaining();
			if (TimeLeft < StartTimeForBlend) 
			{
				float Value = Math::Clamp(TimeLeft/StartTimeForBlend, 0.0, 1.0);
				Audio::UpdateListenerTransform(Player, Value, Listener);
			}
			else 
			{
				if (Camera != nullptr)
					Listener.SetWorldTransform(Camera.GetWorldTransform());	
			}
		}
		else
		{
			if (SizePercentage <= 0.0)
			{
				auto OtherPlayerCamera = OtherPlayer.GetCurrentlyUsedCamera();
				if (OtherPlayerCamera != nullptr)
					Listener.SetWorldTransform(OtherPlayerCamera.GetWorldTransform());	
			}
			else if (SizePercentage >= 1.0)
			{
				if (Camera != nullptr)
					Listener.SetWorldTransform(Camera.GetWorldTransform());	
			}
			else if (hasChanged)
			{
				float NormalizedSize = Math::Abs(SizePercentage-0.5);
				Audio::UpdateListenerTransform(Player, NormalizedSize/0.5, Listener);
			}
		}

		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Audio::DebugListenerLocations(Player);
		}	
	}
}