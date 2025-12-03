class UDefaultProxyTemporalLogExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Proxy Emitter Temporal Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
	#if EDITOR
		auto Capability = Cast<UHazePlayerCapability>(Report.AssociatedObject);
		return Capability != nullptr;
	#else
		return false;
	#endif
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{	
		#if TEST
		FHazeImmediateSectionHandle Section = Drawer.Begin();
		FHazeImmediateHorizontalBoxHandle Box = Section.HorizontalBox();	
		if(Box.Button("Toggle Proxy Bypass"))
		{
			auto Capability = Cast<UHazePlayerCapability>(Report.AssociatedObject);
			if(Capability != nullptr)
			{			
				if(!Capability.IsBlocked())
				{
					Capability.Player.BlockCapabilities(Audio::Tags::DefaultProxyEmitter, this);
					Capability.Player.BlockCapabilities(Audio::Tags::SidescrollerProxyEmitter, this);
				}
				else
				{
					Capability.Player.UnblockCapabilities(Audio::Tags::DefaultProxyEmitter, this);
					Capability.Player.UnblockCapabilities(Audio::Tags::SidescrollerProxyEmitter, this);
				}	
			}
		}
		#endif		
	}
}
UCLASS(Abstract)
class UPlayerProxyEmitterSpatializationBaseCapability : UHazePlayerCapability
{
	// VO Settings
	UPROPERTY(EditDefaultsOnly)
	UHazeAudioAuxBus MioVoProxyBus = nullptr;	

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioAuxBus ZoeVoProxyBus = nullptr;

	// If we want to limit aux sends too.
	UPROPERTY(EditDefaultsOnly)
	TArray<FHazeProxyEmitterUserAuxTargetData> VoUserAuxSends;	
	//

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioAuxBus MioProxyBus = nullptr;	

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioAuxBus ZoeProxyBus = nullptr;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioRtpc MioLRPanningRtpc = nullptr;	

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioRtpc ZoeLRPanningRtpc = nullptr;

	// If we want to limit aux sends too.
	UPROPERTY(EditDefaultsOnly)
	TArray<FHazeProxyEmitterUserAuxTargetData> UserAuxSends;	

	protected float AttenuationScaling = 1.0;
	protected float MakeUpGain = 0.0;
	protected float ReverbSendVolume = 0.0;
	protected float OutBusVolume = 0.0;
	protected float InterpolationTime = 0.0;

	protected FHazeProxyEmitterRequest VoProxyRequest;
	protected FHazeProxyEmitterRequest ProxyRequest;
	protected UHazeAudioAuxBus VoProxyBus;
	protected UHazeAudioAuxBus ProxyBus;
	protected UHazeAudioRtpc LRPanningRTPCID;

	protected float DefaultIdealCameraDistance = 0.0;
	protected float InterpAlpha = 0.0;
	protected float ProxyListenerInterpAlpha = 0.0;
	protected float ListenerLerpAlpha = 0.0;

	protected UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	protected UCameraUserComponent CameraUserComp;
	protected UCameraSettings CameraSettings;
	protected AHazeCameraVolume CameraVolume = nullptr;

	protected UPlayerDefaultProxyEmitterActivationSettings ProxyActivationSettings;

	protected FName ProxyTag = NAME_None;

	const float DEFAULT_CAMERA_DISTANCE_TO_EARS = 600.0;
	protected float MAX_TRACKED_CAMERA_DISTANCE_TO_EARS = 3000.0;

	protected bool bListenerWasMoved = false;

	private FHazeAcceleratedVector AccVector;
	private FVector2D PreviousScreenPos;
	private FVector PreviousListenerPos;

	#if TEST
	bool bBypass = false;
	#endif

	FVector GetPlayerViewLocation() const property
	{
		return Player.ViewLocation;
	}

	FRotator GetPlayerViewRotation() const property
	{
		return Player.ViewRotation;
	}

	float GetListenerDistToPlayerSqrd() const property
	{
		return Player.PlayerListener.WorldLocation.DistSquared(Audio::GetEarsLocation(Player));
	}

	float GetCameraDistToPlayerSqrd() const property
	{
		return PlayerViewLocation.DistSquared(Audio::GetEarsLocation(Player));
	}

	float GetDistanceToPlayerCamera() const property
	{
		return Audio::GetEarsLocation(Player).Distance(PlayerViewLocation);
	}

	float GetDistanceToFocusCamera() const property
	{
		return CameraVolume.CameraSettings.Camera.ActorLocation.Distance(PlayerViewLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{	
		CameraUserComp = UCameraUserComponent::Get(Player);	
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
		DefaultIdealCameraDistance = CameraSettings.IdealDistance.Value;
		
		VoProxyBus = Player.IsMio() ? MioVoProxyBus : ZoeVoProxyBus;
		ProxyBus = Player.IsMio() ? MioProxyBus : ZoeProxyBus;
		if (MioLRPanningRtpc != nullptr && ZoeLRPanningRtpc != nullptr)
			LRPanningRTPCID = Player.IsMio() ? MioLRPanningRtpc : ZoeLRPanningRtpc;

		ProxyActivationSettings = UPlayerDefaultProxyEmitterActivationSettings::GetSettings(Player);

		#if TEST
		TemporalLog::RegisterExtender(this, Player, "Audio/AuxProxy", n"DefaultProxyTemporalLogExtender");
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		CameraVolume = nullptr;		
		TArray<AActor> CameraVolumes;
		Player.GetOverlappingActors(CameraVolumes, AHazeCameraVolume);
		if(CameraVolumes.Num() > 0)
		{
			CameraVolume = Cast<AHazeCameraVolume>(CameraVolumes[0]);
		}

		if(!devEnsure(ProxyTag != NAME_None, "Must set a tag for default proxy request capabilities!"))
			return;
			
		if (VoProxyBus != nullptr && ProxyActivationSettings.bOverride_bIncludeVOInDefaultProxies)
		{
			auto VoEmitter = Audio::GetPlayerVoEmitter(Player);

			VoProxyRequest.OnProxyRequest = FOnProxyEmittersRequest(this, n"OnRequestProxyEmitters");
			VoProxyRequest.Instigator = FInstigator(this, ProxyTag);
			VoProxyRequest.Priority = 2;
			VoProxyRequest.Target = VoEmitter;
			VoProxyRequest.AuxBus = VoProxyBus;
			VoProxyRequest.InBusVolume = MakeUpGain;
			VoProxyRequest.AttenuationScaling = AttenuationScaling;
			VoProxyRequest.ReverbSendVolume = ReverbSendVolume;
			VoProxyRequest.OutBusVolume = OutBusVolume;
			VoProxyRequest.InterpolationTime = InterpolationTime;
			VoProxyRequest.UserAuxTargets = VoUserAuxSends;

			VoEmitter.RequestAuxSendProxy(VoProxyRequest);
		}

		ProxyRequest.OnProxyRequest = FOnProxyEmittersRequest(this, n"OnRequestProxyEmitters");
		ProxyRequest.Instigator = FInstigator(this, ProxyTag);
		ProxyRequest.Priority = 0; // MUST BE ZERO FOR DEFAULT PROXY REQUESTS!
		ProxyRequest.Target = Player;
		ProxyRequest.AuxBus = ProxyBus;
		ProxyRequest.InBusVolume = MakeUpGain;
		ProxyRequest.AttenuationScaling = AttenuationScaling;
		ProxyRequest.ReverbSendVolume = ReverbSendVolume;
		ProxyRequest.OutBusVolume = OutBusVolume;
		ProxyRequest.InterpolationTime = InterpolationTime;
		ProxyRequest.UserAuxTargets = UserAuxSends;

		Player.RequestAuxSendProxy(ProxyRequest);

		// Block default listener 
		Player.BlockCapabilities(Audio::Tags::DefaultListener, this);
		Player.BlockCapabilities(Audio::Tags::LevelSpecificListener, this);

		InterpAlpha = 0.0;
		ProxyListenerInterpAlpha = 0.0;

		AccVector.SnapTo(Player.PlayerListener.WorldLocation);
		PreviousListenerPos = Player.PlayerListener.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ProxyRequest.OnProxyRequest.Clear();
		Player.UnblockCapabilities(Audio::Tags::DefaultListener, this);
		Player.UnblockCapabilities(Audio::Tags::LevelSpecificListener, this);
	}

	protected bool CanSetProxyListenerTransform() const
	{
		if(Player.IsAnyCapabilityActive(Audio::Tags::ProxyListenerBlocker))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		const bool bSetListenerTransform = CanSetProxyListenerTransform();
		if(bSetListenerTransform)
		{
			const FVector PlayerEarsLocation = Audio::GetEarsLocation(Player);

			auto ViewLocation = GetPlayerViewLocation();

			// Alpha for lerping back location of listener, based on a static range of reasonable distances in normal Third-Person gameplay
			FVector ListenerViewDistanceVector =  ViewLocation - PlayerEarsLocation;
			FVector ListenerToView = ListenerViewDistanceVector.GetSafeNormal();
		
			const float ProxyActivationDistance = DefaultIdealCameraDistance + (ProxyActivationSettings.CameraDistanceActivationBufferDistance * ProxyRequest.AttenuationScaling);
			const float ListenerViewDist = ListenerViewDistanceVector.Size();
			const float ScaledMaxTrackingDistance = MAX_TRACKED_CAMERA_DISTANCE_TO_EARS * ProxyRequest.AttenuationScaling;			
		
			const float ProxyLerpAlpha = Math::GetMappedRangeValueClamped(FVector2D(ProxyActivationDistance, ScaledMaxTrackingDistance), FVector2D(0.0, 1.0), ListenerViewDist);
			const FVector ListenerLerpStartPos = PlayerEarsLocation;

			FVector ListenerLerpEndPos = ViewLocation;
			if(ListenerViewDist > ScaledMaxTrackingDistance)
			{
				ListenerLerpEndPos = PlayerEarsLocation + (ListenerToView * ScaledMaxTrackingDistance);
			}						

			ProxyListenerInterpAlpha = Math::FInterpTo(ProxyListenerInterpAlpha, ProxyLerpAlpha, DeltaTime, 10.0);		

			// ListenerLerpAlpha = Math::FInterpTo(ListenerLerpAlpha, ProxyLerpAlpha, DeltaTime, 10);	
			// FVector LerpedPlayerListenerLocation = Math::Lerp(PreviousListenerPos, ProxyListenerLocation, ListenerLerpAlpha);
			// FTransform LerpedProxyListenerTransform = FTransform(Player.ViewRotation, AccVector.AccelerateTo(LerpedPlayerListenerLocation, 0.5, DeltaTime));
			// FVector LerpedPlayerListenerLocation = Math::VInterpTo(PreviousListenerPos, ProxyListenerLocation, DeltaTime, 10.0);
			// FTransform LerpedProxyListenerTransform = FTransform(Player.ViewRotation, AccVector.AccelerateTo(LerpedPlayerListenerLocation, 0.5, DeltaTime));

			FVector LerpedPlayerListenerLocation = PlayerEarsLocation + (ListenerToView * (ScaledMaxTrackingDistance * ProxyListenerInterpAlpha));
			FTransform LerpedProxyListenerTransform = FTransform(PlayerViewRotation, AccVector.AccelerateTo(LerpedPlayerListenerLocation, 0.5, DeltaTime));

			Player.PlayerListener.SetWorldTransform(LerpedProxyListenerTransform);	

			// Used to track deactivation
			bListenerWasMoved = !LerpedPlayerListenerLocation.Equals(PreviousListenerPos, 10.0);	
			PreviousListenerPos = LerpedPlayerListenerLocation;

			#if TEST	
			if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioViewportVisualization::Proxy))
			{
				Audio::DebugListenerLocations(Player);

				Debug::DrawDebugPoint(ListenerLerpStartPos, 20.f, FLinearColor::Yellow, bDrawInForeground = true);
				Debug::DrawDebugString(ListenerLerpStartPos, f"{ProxyActivationDistance}", FLinearColor::White, Scale = 1.5);
				Debug::DrawDebugPoint(ViewLocation, 20.f, FLinearColor::DPink, bDrawInForeground = true);
				Debug::DrawDebugString(ViewLocation, f"{ScaledMaxTrackingDistance}", FLinearColor::White, Scale = 1.5);
				Debug::DrawDebugPoint(LerpedProxyListenerTransform.Location, 25.f, FLinearColor::Teal, bDrawInForeground = true);
				Debug::DrawDebugString(LerpedPlayerListenerLocation, f"{Player.GetName().PlainNameString}\nProxy\nListener\nPos", FLinearColor::Yellow, Scale = 1.2);
			}		
			#endif
		}

		// SET GLOBAL PANNING RTPCS
		SetScreenPositionPanning();

		// OLD BEHAVIOUR
		// // Alpha for crossfading into Proxy AuxBus-send
		// float PreviousInterpAlpha = InterpAlpha;
		// //InterpAlpha = Math::Saturate(Math::FInterpConstantTo(InterpAlpha, ProxyLerpAlpha, DeltaTime, 5.0));
		// InterpAlpha = Math::Saturate(Math::FInterpConstantTo(InterpAlpha, (CameraDistToPlayerSqrd / MaxTrackedCameraDistanceSqrd), DeltaTime, 5.0));	
		// if (InterpAlpha != PreviousInterpAlpha)
		// {
		// 	Player.SetAuxSendProxyCrossfade(ProxyBus, InterpAlpha);	
		// }
	}

	private void SetScreenPositionPanning()
	{
		bool bHorizontalPanning = false;

		auto ScreenMode = SceneView::SplitScreenMode;
		if (ScreenMode == EHazeSplitScreenMode::CustomMerge || ScreenMode == EHazeSplitScreenMode::ManualViews)
		{
			FVector2D Min, Max;
			SceneView::GetPercentageScreenRectFor(Player, Min, Max);

			// Is it vertical or horizontal
			if (Math::IsNearlyZero(Min.X) && Math::IsNearlyEqual(Max.X, 1))
			{
				bHorizontalPanning = true;
			}
			else
			{
				bHorizontalPanning = false;
			}
		}
		else if (SceneView::IsFullScreen() || SceneView::SplitScreenMode == EHazeSplitScreenMode::Horizontal)
		{
			bHorizontalPanning = true;
		}
		else
		{
			bHorizontalPanning = false;
		}

		if(bHorizontalPanning)
		{
			FVector2D ScreenPosition;
			if (!SceneView::ProjectWorldToViewpointRelativePosition(Player, Player.ActorLocation, ScreenPosition))
				return;

			if (PreviousScreenPos == ScreenPosition)
				return;

			PreviousScreenPos = ScreenPosition;	

			const float XAlpha = Math::Saturate(ScreenPosition.X);
			const float XPanning = Math::Lerp(-1, 1, XAlpha);
			const float X = XPanning * Audio::GetPanningRuleMultiplier();			
			AudioComponent::SetGlobalRTPC(LRPanningRTPCID, X, 0);

			if (ScreenMode == EHazeSplitScreenMode::CustomMerge || ScreenMode == EHazeSplitScreenMode::ManualViews)
				Player.PlayerAudioComponent.Panning = X;
		}
		else
		{
			float PanningValue = Player.IsMio() ? -1 : 1;
			float ScreenPercentage = SceneView::GetPlayerViewSizePercentage(Player);
			if (ScreenPercentage > 0.5)
			{
				PanningValue = Math::GetPercentageBetween(1, .5, ScreenPercentage) * PanningValue;
			}

			const float X = PanningValue * Audio::GetPanningRuleMultiplier();		
			AudioComponent::SetGlobalRTPC(LRPanningRTPCID, X, 0);

			// If we have a vertical split, we must update the panning value. Since this capability blocks the default listener.
			Player.PlayerAudioComponent.Panning = PanningValue;
		}
	}

	UFUNCTION(BlueprintEvent)
	bool OnRequestProxyEmitters(UObject Object, FName EmitterName, float32& outInterpolationTime)
	{
		devCheck(false, "Proxy Spatialization Capabilities must override OnRequestProxyEmitters!");
		return false;
	}
}
