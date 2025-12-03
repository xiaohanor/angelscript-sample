
UCLASS(Abstract)
class UWorld_Prison_MaxSecurity_Interactable_LaserCutterWelderBot_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible)
	UHazeAudioEmitter LaserImpactEmitter;

	AMaxSecurityLaserCutterWelderBot WelderBot;
	FVector2D PreviousBotScreenPosition;
	FVector2D PreviousLaserScreenPosition;

	bool bDropFinished = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		WelderBot = Cast<AMaxSecurityLaserCutterWelderBot>(HazeOwner);
		WelderBot.OnBotDestroyed.AddUFunction(this, n"OnBotDestroyed");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		return WelderBot.bDropStarted;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WelderBot.bDropStarted)
			return true;

		if(!DefaultEmitter.IsPlaying())
			return true;

		if(WelderBot.bLaunched && !DefaultEmitter.IsPlaying())
			return true;

		return false;
	}

	UFUNCTION(BlueprintEvent)
	void StartMoving() {};

	UFUNCTION(BlueprintEvent)
	void OnBotDestroyed() {};

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WelderBot.bDropStarted = false;
		bDropFinished = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(!bDropFinished && WelderBot.bDropped)
		{
			bDropFinished = true;
			StartMoving();
		}

		LaserImpactEmitter.AudioComponent.SetWorldLocation(WelderBot.CurrentWeldLocation);

		AHazePlayerCharacter FullscreenPlayer = SceneView::GetFullScreenPlayer();

		FVector2D BotScreenPosition;
		if (!SceneView::ProjectWorldToViewpointRelativePosition(FullscreenPlayer, WelderBot.BotRoot.WorldLocation, BotScreenPosition))
			return;

		if (PreviousBotScreenPosition == BotScreenPosition)
			return;

		PreviousBotScreenPosition = BotScreenPosition;
		const float BotAlpha = Math::GetPercentageBetween(0, 1, BotScreenPosition.X);	
		const float BotPanning = Math::GetMappedRangeValueClamped(FVector2D(0.25, 0.75), FVector2D(-1.0, 1.0), BotAlpha);

		DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, BotPanning, 0.0);

		FVector2D LaserScreenPosition;
		if (!SceneView::ProjectWorldToViewpointRelativePosition(FullscreenPlayer, WelderBot.CurrentWeldLocation, LaserScreenPosition))
			return;

		if (PreviousLaserScreenPosition == LaserScreenPosition)
			return;

		PreviousLaserScreenPosition = LaserScreenPosition;
		const float LaserAlpha = Math::GetPercentageBetween(0, 1, LaserScreenPosition.X);	
		const float LaserPanning = Math::GetMappedRangeValueClamped(FVector2D(0.25, 0.75), FVector2D(-1.0, 1.0), LaserAlpha);

		LaserImpactEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, LaserPanning, 0.0); 
	}
}