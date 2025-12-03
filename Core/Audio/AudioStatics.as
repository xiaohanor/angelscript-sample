namespace Audio
{
	const EHazeTickGroup ListenerTickGroup = EHazeTickGroup::BeforeGameplay;

	namespace Tags
	{
		const FName Listener = n"Listener";
		const FName DefaultListener = n"DefaultListener";
		const FName CutsceneListener = n"CutsceneListener";
		const FName Fullscreen = n"Fullscreen";
		const FName Sidescroller = n"Sidescroller";
		const FName DefaultProxyEmitter = n"DefaultProxyEmitter";
		const FName SidescrollerProxyEmitter = n"SidescrollerProxyEmitter";
		const FName LevelSpecificProxyEmitter = n"LevelSpecificProxyEmitter";

		const FName LevelSpecificListener = n"LevelSpecificListener";

		const FName ProxyListenerBlocker = n"ProxyListenerBlocker";

		namespace Prison
		{
			const FName DroneListener = n"DroneListener";
		}

		namespace Summit
		{
			const FName AcidListener = n"AcidListener";
			const FName TailListener = n"TailListener";
			const FName TopDownDragonListener = n"TopDownDragonListener";
		}

		namespace Skyline
		{
			const FName CarListener = n"CarListener";
			const FName GravityBikeListener = n"GravityBikeListener";
		}

		//
		const FName ReflectionTracing = n"ReflectionTracing";
		const FName DefaultReflectionTracing = n"DefaultReflectionTracing";
		const FName FullscreenReflectionTracing = n"FullscreenReflectionTracing";
		const FName StaticReflectionTracing = n"StaticReflectionTracing";

		const FName LevelSpecificTracingBlocking = n"LevelSpecificTracingBlocking";

		// WINGSUIT
		const FName WingSuitListener = n"WingSuitListener";
		//
	}

	namespace Names
	{
		const FName DefaultVoiceLineEmitterName = n"VO_Emitter";
	}

	namespace Materials
	{
		UFUNCTION(BlueprintPure)
		UPhysicalMaterialAudioAsset GetGroundAudioPhysMat(AHazeActor Actor)
		{
			UPhysicalMaterialAudioAsset AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(UPhysicalMaterialAudioAsset.DefaultObject);

			if(Actor == nullptr)
				return AudioPhysMat;

			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Actor);
			if(MoveComp == nullptr)
				return AudioPhysMat;

			if(!MoveComp.HasGroundContact())
				return AudioPhysMat;

			FHitResult HitResult = MoveComp.GetGroundContact().ConvertToHitResult();

			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);;
			TraceSettings.IgnoreActor(Actor);

			UPhysicalMaterial PhysMat = AudioTrace::GetPhysMaterialFromHit(HitResult, TraceSettings);
			if(PhysMat == nullptr)
				return AudioPhysMat;

			AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);
			return AudioPhysMat;
		}
	}
}

namespace Audio
{
	const float VERY_SMALL_NUMBER = 1.e-32;

	UFUNCTION(BlueprintPure)
	float AmplitudeToDb(const float& Amplitude)
	{
		// This was the previous behaviour on PC.
		if (Amplitude < VERY_SMALL_NUMBER)
			return -96;
		
		// Any value =< 0 will result in NaN, on some platforms that will be a negative value, some a positive for instance on the PS5.
		auto LogResult = Math::LogX(10, Math::Clamp(Amplitude, VERY_SMALL_NUMBER, MAX_flt));

		// if (!devEnsure(Math::IsFinite(LogResult), f"AmplitudeToDb-> Log10 resulted in a NaN value from a value of '{Amplitude}'! \n Returns -96 instead."))
		// {
 		// 	return -96;
		// }

		return Math::Clamp(LogResult * 20, -96, 36);
	}

	UFUNCTION(BlueprintPure)
	float DbToAmplitude(const float& dB)
	{
		return Math::Pow(10, Math::Clamp(dB, -96, 48)/20);
	}

	FVector GetEarsLocation(const AHazePlayerCharacter Player)
	{
		FVector EarsLocation = Player.Mesh.GetSocketLocation(n"Head");

		return EarsLocation;
	}

	FTransform GetEarsTransform(AHazePlayerCharacter Player)
	{
		return Player.Mesh.GetSocketTransform(n"Head");
	}

	FTransform CreateListenerTransform(AHazePlayerCharacter Player, float Alpha)
	{
		auto PlayerTransform = Player.GetViewTransform();
		PlayerTransform.SetLocation(Math::Lerp(GetEarsLocation(Player), PlayerTransform.GetLocation(), Alpha));
		return PlayerTransform;
	}

	void UpdateListenerTransform(AHazePlayerCharacter Player, float Alpha, UHazeAudioListenerComponent Listener)
	{
		UHazeAudioListenerComponent ListenerComp = Listener != nullptr ? Listener : UHazeAudioListenerComponent::Get(Player);
		if (ListenerComp == nullptr)
			return;

		ListenerComp.SetWorldTransform(CreateListenerTransform(Player, Alpha));
	}

	void DebugListenerLocations(AHazePlayerCharacter Player, UObject ObjectOverride = nullptr, FVector OverridePosition = FVector())
	{
		FVector CameraLocation = ObjectOverride != nullptr ? OverridePosition : Player.GetViewLocation();

		UHazeAudioListenerComponent ListenerComp = Player.PlayerListener;
		FVector ListenerLocation = ListenerComp.GetWorldLocation();
		// FRotator ListenerRotation = ListenerComp.GetWorldRotation();

		Debug::DrawDebugArrow(ListenerLocation, ListenerLocation + (ListenerComp.ForwardVector * 500), 40, FLinearColor::Blue, 10);
		Debug::DrawDebugPoint(GetEarsLocation(Player), 10.0, FLinearColor(1.0, 0.0, 0.0), bDrawInForeground = true);
		Debug::DrawDebugPoint(CameraLocation, 10.0, FLinearColor::Blue);
		Debug::DrawDebugPoint(ListenerLocation, 20.0, FLinearColor::Purple, bDrawInForeground = true);

		if(Player.IsMio())
			Debug::DrawDebugString(ListenerLocation, "MIO - LISTENER", FLinearColor::Blue, bOutline = false);
		else
			Debug::DrawDebugString(ListenerLocation, "ZOE - LISTENER", FLinearColor::Green, bOutline = false);
	}

	float NormalizeRangeTo01(const float Value, const float InMin, const float InMax)
	{
		return Math::Clamp(Math::Lerp(0, 1, Math::GetPercentageBetween(InMin, InMax, Value)), 0, 1);
	}

	void OverridePlayerComponentAttach(AHazePlayerCharacter Player, USceneComponent SceneComp, const FName SocketName = NAME_None)
	{
		if(Player != nullptr && SceneComp != nullptr)
		{
			Player.PlayerAudioComponent.AttachToComponent(SceneComp, SocketName);
			Player.PlayerAudioComponent.ReverbComponent.AttachToComponent(SceneComp, SocketName);
		}
	}

	void ResetPlayerComponentAttach(AHazePlayerCharacter Player)
	{
		if(Player != nullptr)
		{
			if(Player.PlayerAudioComponent != nullptr)
			{
				Player.PlayerAudioComponent.AttachToComponent(Player.Mesh, n"Hips");
				
				if(Player.PlayerAudioComponent.ReverbComponent != nullptr)
				{
					Player.PlayerAudioComponent.ReverbComponent.AttachToComponent(Player.Mesh, n"Head");
				}
				else
				{
					PrintWarning(f"ResetPlayerComponentAttach(): ReverbComponent on {Player.Name} was nullptr!");
				}
			}
			else
			{
				PrintWarning(f"ResetPlayerComponentAttach(): PlayerAudioComponent on {Player.Name} was nullptr!");
			}
		}
	}

	UFUNCTION(BlueprintPure)
	bool GetScreenPositionRelativePanningValue(FVector WorldLocation, FVector2D& PreviousScreenPosition, float&out X, float&out Y)
	{
		FVector2D ScreenPosition;
		if (!SceneView::ProjectWorldToViewpointRelativePosition(SceneView::FullScreenPlayer, WorldLocation, ScreenPosition))
			return false;

		if (PreviousScreenPosition == ScreenPosition)
			return false;

		PreviousScreenPosition = ScreenPosition;

		const float XAlpha = Math::Saturate(ScreenPosition.X);
		const float XPanning = Math::Lerp(-1, 1, XAlpha);
		X = XPanning * Audio::GetPanningRuleMultiplier();

		const float YAlpha = Math::Saturate(ScreenPosition.Y);
		Y = Math::Lerp(-1.0, 1.0, YAlpha);

		return true;
	}

	UFUNCTION(BlueprintPure)
	float GetPlayerPanningValue(AHazePlayerCharacter Player)
	{
		if(Player == nullptr)
			return 0.0;

		const float PanningValue = Player.IsMio() ?  -1.0 : 1.0;
		return PanningValue * Audio::GetPanningRuleMultiplier();
	}

	void SetScreenPositionRelativePanning(AHazePlayerCharacter Player, AHazePlayerCharacter OtherPlayer, FVector2D& PreviousScreenPosition)
	{
		auto TargetPlayer = Player;
		// if the other player isn't in view, use the other players view instead.
		if (!SceneView::IsInView(Player, Player.ActorLocation))
		{
			TargetPlayer = OtherPlayer;
		}

		FVector2D ScreenPosition;
		if (!SceneView::ProjectWorldToViewpointRelativePosition(TargetPlayer, TargetPlayer.ActorLocation, ScreenPosition))
			return;

		if (PreviousScreenPosition == ScreenPosition)
			return;
		PreviousScreenPosition = ScreenPosition;

		const float Alpha = Math::GetPercentageBetween(0, 1, ScreenPosition.X);
		const float Panning = Math::Lerp(-1, 1, Alpha);

		Player.PlayerAudioComponent.Panning = Panning;
	}

	void SetSidescrollerScreenPositionRelativePanning(AHazePlayerCharacter Player, AHazePlayerCharacter OtherPlayer, FVector2D& PreviousScreenPosition)
	{
		auto TargetPlayer = Player;
		// if the other player isn't in view, use the other players view instead.
		if (!SceneView::IsInView(Player, Player.ActorLocation))
		{
			TargetPlayer = OtherPlayer;
		}

		FVector2D ScreenPosition;
		if (!SceneView::ProjectWorldToViewpointRelativePosition(TargetPlayer, TargetPlayer.ActorLocation, ScreenPosition))
			return;

		if (PreviousScreenPosition == ScreenPosition)
			return;

		PreviousScreenPosition = ScreenPosition;

		const float Alpha = Math::GetPercentageBetween(0, 1, ScreenPosition.X);
		float Panning = Alpha;

		// Absolute panning will be from middle of screen (or wherever the vertical split happens)
		// Flip relationship for Mio so that -1 equals all the way to the left
		if(Player.IsMio())
		{
			Panning *= -1;
			Panning += -Alpha;
		}			

		Player.PlayerAudioComponent.Panning = Panning;
	}

	void SetPanningBasedOnScreenPercentage(AHazePlayerCharacter Player)
	{
		if (SceneView::SplitScreenMode == EHazeSplitScreenMode::Horizontal)
			return;

		float PanningValue = Player.IsMio() ? -1 : 1;
		float ScreenPercentage = SceneView::GetPlayerViewSizePercentage(Player);
		if (ScreenPercentage > 0.5)
		{
			PanningValue = Math::GetPercentageBetween(1, .5, ScreenPercentage) * PanningValue;
		}

		Player.PlayerAudioComponent.Panning = PanningValue;
	}

	UFUNCTION(BlueprintPure)
	float32 GetGlobalRTPC(UHazeAudioRtpc Rtpc)
	{
		float32 RtpcValue = 0;
		AudioComponent::GetGlobalRTPC(Rtpc.ShortID, RtpcValue);
		return RtpcValue;
	}

	UFUNCTION(BlueprintPure)
	float32 GetCachedGlobalRTPC(UHazeAudioRtpc Rtpc)
	{
		float32 RtpcValue = 0;
		AudioComponent::GetCachedGlobalRTPC(Rtpc.ShortID, RtpcValue);
		return RtpcValue;
	}
	
	UFUNCTION(BlueprintCallable)
	void PostEventOnPlayer(AHazePlayerCharacter Player, UHazeAudioEvent Event, FHazeAudioFireForgetEventParams Params = FHazeAudioFireForgetEventParams(), FName EmitterName = n"DefaultEmitter")
	{
		if(Player == nullptr || Event == nullptr)
			return;

		auto Emitter = Player.PlayerAudioComponent.GetEmitter(Player, EmitterName);
		if(Emitter == nullptr)
			return;

		auto EventInstance = Emitter.PostEvent(Event);
		
		for(auto NodeProperty : Params.NodeProperties)
		{
			EventInstance.SetNodeProperty(NodeProperty.ActorMixer, NodeProperty.Property, NodeProperty.Value, NodeProperty.InterpolationTimeMS);
		}

		for(auto RTPCParam : Params.RTPCs)
		{
			bool _ = EventInstance.SetRTPC(RTPCParam.RTPCAsset, RTPCParam.Value, RTPCParam.InterpolationTimeMS);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetSplineProgression(const FSplinePosition& SplinePosition)
	{
		if (SplinePosition.IsValid() == false)
			return 0;

		return SplinePosition.CurrentSplineDistance / SplinePosition.CurrentSpline.SplineLength;
	}

	UHazeAudioEmitter GetPlayerVoEmitter(AHazePlayerCharacter Player)
	{
		auto AudioComponent = Player.VoComponent;
		return AudioComponent.GetEmitter(Player, Names::DefaultVoiceLineEmitterName);
	}

	// Starts a automatically run audio effect, decided by the Duration either in Asset or DurationOverride.
	UFUNCTION(BlueprintCallable)
	void StartAudioEffectAuto(const FInstigator& Instigator, const UHazeAudioEffectShareSet ShareSet, float DurationOverride = 0)
	{
		auto EffectsSystem = Game::GetSingleton(UHazeAudioRuntimeEffectSystem); 
		if (EffectsSystem == nullptr)
			return;

		EffectsSystem.StartAuto(Instigator, ShareSet, DurationOverride);
	}

	// Starts a user controlled audio effect, the user must set the Alpha and Release if finished with the effect
	UFUNCTION(BlueprintCallable)
	FHazeAudioRuntimeEffectInstance StartAudioEffectControlled(const FInstigator& Instigator, const UHazeAudioEffectShareSet ShareSet)
	{
		auto EffectsSystem = Game::GetSingleton(UHazeAudioRuntimeEffectSystem); 
		if (EffectsSystem == nullptr)
			return FHazeAudioRuntimeEffectInstance();

		return EffectsSystem.StartControlled(Instigator, ShareSet);
	}
}

UFUNCTION(BlueprintPure)
mixin bool AttachedToMio(UHazeSoundDefBase SoundDef)
{
	if(SoundDef == nullptr)
		return false;

	if(SoundDef.PlayerOwner == nullptr)
		return false;

	return SoundDef.PlayerOwner.IsMio();
}

UFUNCTION(BlueprintCallable)
mixin void SetScreenRelativePostionPanning(UHazeAudioEmitter Emitter)
{
	if(Emitter == nullptr)
		return;

	FVector2D Previous;
	float X = 0.0;
	float Y_ = 0.0;
	Audio::GetScreenPositionRelativePanningValue(Emitter.AudioComponent.WorldLocation, Previous, X, Y_);
	Emitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
}

UFUNCTION(BlueprintPure)
mixin FVector GetEmitterLocation(UHazeAudioEmitter Emitter)
{
	if(Emitter == nullptr || Emitter.AudioComponent == nullptr)
		return FVector::ZeroVector;
	
	if(!Emitter.AudioComponent.IsUsingMultiplePositions())
		return Emitter.AudioComponent.GetWorldLocation();

	float ClosestDist = MAX_flt;
	FVector ClosestPos;
	
	TArray<FAkSoundPosition> SoundPositions = Emitter.AudioComponent.GetMultipleSoundPositions();

	for(auto Player : Game::Players)
	{
		for(auto SoundPos : SoundPositions)
		{		
			const float PositionDistance = Player.ActorLocation.DistSquared(SoundPos.Position);

			if(PositionDistance < ClosestDist)
			{
				ClosestDist = PositionDistance;
				ClosestPos = SoundPos.Position;
			}
		}
	}

	return ClosestPos;
}

UFUNCTION(BlueprintCallable)
mixin void SetEmitterLocation(UHazeAudioEmitter Emitter, FVector WorldLocation, bool bDetachFromOwner = false)
{
	if(Emitter == nullptr || Emitter.AudioComponent == nullptr)
		return;

	if(bDetachFromOwner)
		Emitter.AudioComponent.DetachFromComponent();

	Emitter.AudioComponent.SetWorldLocation(WorldLocation);
}

UFUNCTION(BlueprintCallable)
mixin void SetEmitterRotation(UHazeAudioEmitter Emitter, FRotator Rotation)
{
	if(Emitter == nullptr || Emitter.AudioComponent == nullptr)
		return;

	Emitter.AudioComponent.SetRelativeRotation(Rotation);
}

UFUNCTION(BlueprintCallable)
mixin UHazeAudioEmitter AttachEmitterTo(UHazeAudioEmitter Emitter, USceneComponent Component, const FName& InSocketName = NAME_None)
{
	if(Emitter == nullptr || Emitter.AudioComponent == nullptr || Component == nullptr)
		return nullptr;


	Emitter.AudioComponent.AttachTo(Component, InSocketName, EAttachLocation::SnapToTarget);
	return Emitter;
}

UFUNCTION(BlueprintCallable)
mixin void SetMultiplePositions(UHazeAudioEmitter Emitter, const TArray<FAkSoundPosition>& Positions, AkMultiPositionType PositioningType = AkMultiPositionType::MultiDirections)
{
	if(Emitter == nullptr || Emitter.AudioComponent == nullptr)
		return;

	Emitter.AudioComponent.SetMultipleSoundPositions(Positions, PositioningType);
}

UFUNCTION(BlueprintCallable)
mixin void ClearMultiplePositions(UHazeAudioEmitter Emitter)
{
	if(Emitter == nullptr || Emitter.AudioComponent == nullptr || !Emitter.AudioComponent.IsUsingMultiplePositions())
		return;

	TArray<FAkSoundPosition> Empty;
	Emitter.AudioComponent.SetMultipleSoundPositions(Empty);
}

namespace Music
{
	UHazeAudioMusicManager Get()
	{
		return UHazeAudioMusicManager::Get();
	}

	AHazeActor GetActor()
	{
		return UHazeAudioMusicManager::GetActor();
	}

	void LinkMusicActorToReceiveEffectEventsFrom(AHazeActor InActor)
	{
		if (InActor == nullptr)
			return;

		EffectEvent::LinkActorToReceiveEffectEventsFrom(GetActor(), InActor);
	}
}