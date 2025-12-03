class AGiantsAudioLevelScriptActor : AAudioLevelScriptActor
{
	UPROPERTY(EditDefaultsOnly)
	bool bNewYorkGiantsSwingDone = false;

	FHazeAudioID AxeGiantGlobalDuckingRTPC = FHazeAudioID("Rtpc_World_Giants_AxeGiant_GlobalDucking");
	float DuckingRTPCValue = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		AudioComponent::SetGlobalRTPC(AxeGiantGlobalDuckingRTPC, 0.0);
	}

	UFUNCTION(BlueprintCallable)
	void SetAxeGiantGlobalDuckingRTPCValue(ASplineActor CorridorSpline)
	{
		if(CorridorSpline == nullptr)
			return;

		float MinAlpha = MAX_flt;
		for(auto Player : Game::GetPlayers())
		{
			const float PlayerSplineAlpha = CorridorSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation)
			 								/ CorridorSpline.Spline.SplineLength;

			MinAlpha = Math::Min(MinAlpha, PlayerSplineAlpha);
		}

		if(MinAlpha != DuckingRTPCValue)
		{
			DuckingRTPCValue = MinAlpha;
			AudioComponent::SetGlobalRTPC(AxeGiantGlobalDuckingRTPC, DuckingRTPCValue);
		}
	}	

	
}