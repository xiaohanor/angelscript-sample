
UCLASS(Abstract)
class UGameplay_Creature_Tundra_Shapeshift_MonkeyRealm_MonkeyConga_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnCollidedWithCongaLine(FCongaLinePLayerOnCollidedWithCongaLineEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnHitWall(FCongaLinePLayerOnHitWallEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnSwitchedOutOfSnowMonkeyForm(FCongaLinePLayerOnSwitchedOutOfSnowMonkeyFormEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnLastDancerExited(FCongaLinePLayerOnLastDancerExitedEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnDancerEntered(FCongaLinePLayerOnDancerEnteredEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnDancerStartedEntering(FCongaLinePLayerOnDancerStartedEnteringEventData EventData){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void OnStartMonkeyLandOnHead() {};

	UFUNCTION(BlueprintEvent)
	void OnStopMonkeyLandOnHead() {};

	UPROPERTY(NotVisible, BlueprintReadOnly)
	UHazeAudioEmitter CongaLineEmitter;

	UPROPERTY(EditDefaultsOnly, Category = "Body Movement")
	TArray<FName> BodySocketNames;
	default BodySocketNames.Add(n"LeftHand");
	default BodySocketNames.Add(n"RightHand");
	default BodySocketNames.Add(n"LeftFoot");
	default BodySocketNames.Add(n"RightFoot");

	UPROPERTY(EditDefaultsOnly, Category = "Body Movement")
	float MaxBodyMovementSpeedCombined = 350;

	UPROPERTY(EditDefaultsOnly, Category = "Proxy")
	UHazeAudioRtpc PanningRTPC;

	private TArray<FVector> CachedBodyLocations;
	private TArray<float> CachedSocketSpeeds;
	private FHazeAudioID PanningRtpcID = FHazeAudioID("Rtpc_SpeakerPanning_LR");

	private float NormalizedBodyMovementSpeedCombined = 0.0;

	AHazePlayerCharacter Player;
	USkeletalMeshComponent MeshComp;
	UCongaLinePlayerComponent CongaPlayerComp;

	private FVector2D PreviousScreenPosition;
	private FVector PreviousCongaLineEmitterPosition;
	private FVector2D PreviousCongaLineEmitterScreenPosition;

	UFUNCTION(BlueprintEvent)
	void OnFootstep_Plant() {}

	UFUNCTION(BlueprintEvent)
	void OnFootstep_Release() {}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MeshComp = USkeletalMeshComponent::Get(HazeOwner);

		CachedBodyLocations.SetNum(BodySocketNames.Num());
		CachedSocketSpeeds.SetNum(BodySocketNames.Num());

		Player = Cast<ATundraPlayerSnowMonkeyActor>(HazeOwner) != nullptr ? Game::GetMio() : Game::GetZoe();
		CongaPlayerComp = UCongaLinePlayerComponent::Get(Player);
	}

	/*UFUNCTION(BlueprintOverride)
	bool GetScriptImplementedTriggerEffectEvents(
												 UHazeEffectEventHandlerComponent& EventHandlerComponent,
												 TMap<FName,TSubclassOf<UHazeEffectEventHandler>>& EventClassAndFunctionNames) const
	{
		EventHandlerComponent = UHazeEffectEventHandlerComponent::Get(HazeOwner);
		EventClassAndFunctionNames.Add(n"OnStartMonkeyOnHead", UDanceShowdownPlayerEventHandler);
		EventClassAndFunctionNames.Add(n"OnStopMonkeyOnHead", UDanceShowdownPlayerEventHandler);
		return true;
	}
	*/
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		ProxyEmitterSoundDef::LinkToActor(this, Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		LerpCongaLineEmitterPosition(DeltaSeconds);
		SetScreenPanning();

		for(int i = 0; i < BodySocketNames.Num(); ++i)
		{
			const FVector SocketLocation = MeshComp.GetSocketLocation(BodySocketNames[i]);
			const FVector SocketVelo = SocketLocation - CachedBodyLocations[i];
			const float SocketSpeed = SocketVelo.Size() / DeltaSeconds;

			CachedSocketSpeeds[i] = SocketSpeed;
			CachedBodyLocations[i] = SocketLocation;
		}

		NormalizedBodyMovementSpeedCombined = Math::Min(1, ((CachedSocketSpeeds[0] + CachedSocketSpeeds[1] + CachedSocketSpeeds[2] + CachedSocketSpeeds[3]) / 4) / MaxBodyMovementSpeedCombined);
	}
	
	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Body Speed Normalized Combined"))
	float GetBodyMovementSpeedCombined()
	{
		return NormalizedBodyMovementSpeedCombined;
	}

	private void SetScreenPanning()
	{
		float PlayerPanning = 0.0;
		float _Y;

		Audio::GetScreenPositionRelativePanningValue(Player.ActorLocation, PreviousScreenPosition, PlayerPanning, _Y);
		AudioComponent::SetGlobalRTPC(PanningRTPC, PlayerPanning);

		float CongaLinePanning = 0.0;

		Audio::GetScreenPositionRelativePanningValue(PreviousCongaLineEmitterPosition, PreviousCongaLineEmitterScreenPosition, CongaLinePanning, _Y);
		CongaLineEmitter.SetRTPC(PanningRtpcID, CongaLinePanning, 0);
	}

	private void LerpCongaLineEmitterPosition(float DeltaTime)
	{
		FVector WantedPosition = Player.GetActorLocation();

		int MiddleDancerIndex = (Math::RoundToInt(CongaPlayerComp.CurrentDancerCount() * 0.5)) - 1;
		if(MiddleDancerIndex >= 0)
		{
			WantedPosition = CongaPlayerComp.GetDancers()[MiddleDancerIndex].Owner.ActorLocation;
			WantedPosition = Math::VInterpConstantTo(PreviousCongaLineEmitterPosition, WantedPosition, DeltaTime, 10000.0);
		}

		CongaLineEmitter.AudioComponent.SetWorldLocation(WantedPosition);
		PreviousCongaLineEmitterPosition = WantedPosition;
	}
}