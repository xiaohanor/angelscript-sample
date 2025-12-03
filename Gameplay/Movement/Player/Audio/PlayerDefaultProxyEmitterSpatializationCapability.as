class UPlayerDefaultProxyEmitterSpatializationCapability : UPlayerProxyEmitterSpatializationBaseCapability
{
	default CapabilityTags.Add(Audio::Tags::DefaultProxyEmitter);
	default ProxyTag = Audio::Tags::DefaultProxyEmitter;
	default InterpolationTime = 1;

	// Set on attenuation curve in Wwise
	const float DEFAULT_AUX_BUS_ATTENUATION_DISTANCE = 3000.0;

	bool bHasLerpedListenerOnDeactivation = true;
	bool bHasSetDeactivationTimer = false;

	bool HasCameraOverride() const
	{
		// TODO: Unsure if we want this. Sometimes not using a default camera means that it's CLOSER than normal.
		// if(!CameraUserComp.IsUsingDefaultCamera())
		// 	return true;

		return DistanceToPlayerCamera > (DefaultIdealCameraDistance + ProxyActivationSettings.CameraDistanceActivationBufferDistance);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		#if TEST
		if(bBypass)
			return false;

		if(CameraUserComp.HasDebugView)
			return false;
		#endif	

		if(!ProxyActivationSettings.bCanActivate)
			return false;

		if (Player.bIsParticipatingInCutscene)
			return false;

		if (Game::IsInLoadingScreen())
			return false;

		if(!HasCameraOverride())
			return false;

		return true;
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		#if TEST
		if(bBypass)
			return true;
		#endif

		if(!ProxyActivationSettings.bCanActivate)
			return true;

		if (Player.bIsParticipatingInCutscene)
			return true;

		if (Game::IsInLoadingScreen())
			return true;

		if(HasCameraOverride())
			return false;

		if(bListenerWasMoved)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bHasLerpedListenerOnDeactivation = false;
		bHasSetDeactivationTimer = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bHasLerpedListenerOnDeactivation = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float AttenuationRange = 0.0;
		switch(PerspectiveModeComp.GetPerspectiveMode())
		{
			// Implement for each perspective as seen needed.
			case EPlayerMovementPerspectiveMode::ThirdPerson:
			case EPlayerMovementPerspectiveMode::TopDown:
			case EPlayerMovementPerspectiveMode::MovingTowardsCamera:
			AttenuationRange = ProxyActivationSettings.DefaultAttenuation;
			break;
			case EPlayerMovementPerspectiveMode::SideScroller:
			AttenuationRange = ProxyActivationSettings.SideScrollerAttenuation;
			break;
		}

		if (AttenuationRange != ProxyRequest.AttenuationScaling)
		{
			ProxyRequest.Instigator = this;
			ProxyRequest.AttenuationScaling = AttenuationRange;
			Player.UpdateProxyRequest(ProxyRequest);			
		}	

		Super::TickActive(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		auto Log = TEMPORAL_LOG(Player, "Audio/AuxProxy");
		Log.Value("Player Default;Camera activation buffer distance: ", ProxyActivationSettings.CameraDistanceActivationBufferDistance).
		Value("Player Default;Ideal Distance: ", CameraSettings.IdealDistance.Value).
		Value("Player Default;Distance To Camera: ", Player.ViewLocation.Distance(Audio::GetEarsLocation(Player)));

		if(!IsActive())
		{
			Log.Value("Player Default;Can Activate: ", ProxyActivationSettings.bCanActivate);
		}		
		else
		{			
			//Log.Value("Player Default;Crossfade Alpha", InterpAlpha).
			Log.Value("Player Default;Can set Listener Transform", CanSetProxyListenerTransform()).
			Value("Player Default;Listener Lerp Alpha", ProxyListenerInterpAlpha).
			// Value("Player Default;Max Tracked Distance To Camera: ", Math::Sqrt(MaxTrackedCameraDistanceSqrd)).
			Value("Player Default;Scaled Attenuation Distance: ", DEFAULT_AUX_BUS_ATTENUATION_DISTANCE * ProxyRequest.AttenuationScaling);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool OnRequestProxyEmitters(UObject Object, FName EmitterName, float32& outInterpolationTime)
	{
		outInterpolationTime = float32(InterpolationTime);

		if (!IsActive())
			return false;

		if(HasCameraOverride() || !bHasLerpedListenerOnDeactivation)
			return true;
		
		return false;
	}
}