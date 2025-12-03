USTRUCT()
struct FCentipedePlayerEmitterData
{
	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEmitter HeadEmitter;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	UPlayerMovementComponent MoveComp;

	UPROPERTY(BlueprintReadOnly)
	UCentipedeBiteComponent BiteComp;

	UPROPERTY(BlueprintReadOnly)
	UPlayerCentipedeSwingComponent SwingComp;

	bool bWasGrounded = true;
	bool bWasSwinging = false;
}

UCLASS(Abstract)
class UGameplay_Character_Creature_Sanctuary_Centipede_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnBiteStarted(FSanctuaryCentipedeBiteEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnBiteStopped(FSanctuaryCentipedeBiteEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnUpdateBurning(FSanctuaryCentipedeBurningEventEventData BurningData){}

	UFUNCTION(BlueprintEvent)
	void OnBurningStopped(){}

	UFUNCTION(BlueprintEvent)
	void OnBurningStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnCentipedeStretchStop(){}

	UFUNCTION(BlueprintEvent)
	void OnCentipedeStretchStart(){}

	UFUNCTION(BlueprintEvent)
	void OnSwingPointReleased(FSanctuaryCentipedeSwingpointEventData Params){}

	UFUNCTION(BlueprintEvent)
	void OnSwingPointAttached(FSanctuaryCentipedeSwingpointEventData Params){}

	UFUNCTION(BlueprintEvent)
	void OnDetachWaterOutlet(FCentipedeWaterOutletEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnAttachWaterOutlet(FCentipedeWaterOutletEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnGateChainGrabbed(FSanctuaryCentipedeGateChainGrabbedData Params){}

	UFUNCTION(BlueprintEvent)
	void OnBiteResponseComponentBitten(){}

	UFUNCTION(BlueprintEvent)
	void OnBurningDeath(){}

	UFUNCTION(BlueprintEvent)
	void OnBiteAnticipationStarted(FCentipedeBiteEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnBiteAnticipationStopped(FCentipedeBiteEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnGateChainReleased(FSanctuaryCentipedeGateChainReleasedData Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter MioHeadEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter ZoeHeadEmitter;

	ACentipede Centipede;
	const float MAX_SWING_SPEED = 4000;
	const float MAX_BODY_STRETCH_HEAD_DISTANCE_SQRD = 2390982;

	// KEEP IN SYNC WITH VALUE SET IN CENTIPEDE ABP
	const float MAX_HEAD_LINEAR_MOVEMENT_SPEED = 900.0;

	const float MIN_CAMERA_DISTANCE_ATTENUATION_RANGE_SQRD = Math::Square(2500);
	const float MAX_CAMERA_DISTANCE_ATTENUATION_RANGE_SQRD = Math::Square(5000);

	FVector2D MioVelocity;
	FVector2D ZoeVelocity;
	
	private TPerPlayer<FCentipedePlayerEmitterData> EmitterDatas;
	FCentipedePlayerEmitterData GetOtherPlayerData(const FCentipedePlayerEmitterData InData)
	{
		return EmitterDatas[InData.Player.OtherPlayer];
	}

	FVector GetBodyMiddlePoint() const property
	{
		const TArray<FVector> BodyLocations = Centipede.GetBodyLocations();
		return BodyLocations[Math::IntegerDivisionTrunc(BodyLocations.Num(), 2)];
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Centipede = Cast<ACentipede>(HazeOwner);

		for(auto Player : Game::GetPlayers())
		{
			EmitterDatas[Player].HeadEmitter = Player.IsMio() ? MioHeadEmitter : ZoeHeadEmitter;
			EmitterDatas[Player].Player = Player;
			EmitterDatas[Player].MoveComp = UPlayerMovementComponent::Get(Player);
			EmitterDatas[Player].BiteComp = UCentipedeBiteComponent::Get(Player);
			EmitterDatas[Player].SwingComp = UPlayerCentipedeSwingComponent::Get(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto& EmitterData : EmitterDatas)
		{					
			OnCentipedeHeadGroundedStart(EmitterData.Player, EmitterData.HeadEmitter);
		}			
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Emitter Data"))
	void GetEmitterData(AHazePlayerCharacter Player, FCentipedePlayerEmitterData&out EmitterData)
	{
		EmitterData = EmitterDatas[Player];
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Emitter Datas"))
	void GetEmitterDatas(TPerPlayer<FCentipedePlayerEmitterData>&out OutEmitterDatas)
	{
		OutEmitterDatas = EmitterDatas;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Head Grounded"))
	bool IsHeadGrounded(const FCentipedePlayerEmitterData& EmitterData)
	{
		return EmitterData.MoveComp.IsOnWalkableGround();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Swinging"))
	bool IsSwinging()
	{
		for(auto& EmitterData : EmitterDatas)
		{
			if(EmitterData.bWasSwinging)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Swing Speed"))
	float GetSwingSpeed()
	{
		if(!IsSwinging())
			return 0.0;

		float SwingSpeed = 0.0;
		for(auto& EmitterData : EmitterDatas)
		{
			if(!EmitterData.bWasSwinging)
				continue;

			SwingSpeed = GetOtherPlayerData(EmitterData).MoveComp.Velocity.Size();
		}

		return Math::Saturate(SwingSpeed / MAX_SWING_SPEED);		
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Body Stretch Length"))
	float GetBodyLength()
	{
		return Math::Saturate(MioHeadEmitter.GetEmitterLocation().DistSquared(ZoeHeadEmitter.GetEmitterLocation()) / MAX_BODY_STRETCH_HEAD_DISTANCE_SQRD);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Normalized View Distance"))
	float GetViewDistanceNormalized()
	{
		auto FullscreenPlayer = SceneView::GetFullScreenPlayer();
		if(FullscreenPlayer == nullptr)
			return 1.0;

		return Math::GetMappedRangeValueClamped(FVector2D(MIN_CAMERA_DISTANCE_ATTENUATION_RANGE_SQRD, MAX_CAMERA_DISTANCE_ATTENUATION_RANGE_SQRD),
		 FVector2D(0.0, 1.0), 
		 FullscreenPlayer.ViewLocation.DistSquared(DefaultEmitter.GetEmitterLocation()));
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Mio Head Feet Speed"))
	float GetMioHeadFeetSpeed()
	{
		return Math::Saturate(MioVelocity.Size() / MAX_HEAD_LINEAR_MOVEMENT_SPEED); 
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Zoe Head Feet Speed"))
	float GetZoeHeadFeetSpeed()
	{
		return Math::Saturate(ZoeVelocity.Size() / MAX_HEAD_LINEAR_MOVEMENT_SPEED); 
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Player Head Has Bite Target"))
	bool GetPlayerHeadHasBiteTarget(AHazePlayerCharacter Player)
	{
		return EmitterDatas[Player].BiteComp.GetTargetedComponent() != nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void OnCentipedeHeadGroundedStart(AHazePlayerCharacter Player, UHazeAudioEmitter HeadEmitter) {};

	UFUNCTION(BlueprintEvent)
	void OnCentipedeHeadAirborneStart(AHazePlayerCharacter Player, UHazeAudioEmitter HeadEmitter, bool bBothHeadsAirborne) {};

	UFUNCTION(BlueprintEvent)
	void OnCentipedeLand(float Strength) {};
	
	UFUNCTION(BlueprintEvent)
	void OnCentipedeSwingStart(AHazePlayerCharacter Player, UHazeAudioEmitter HeadEmitter) {};

	UFUNCTION(BlueprintEvent)
	void OnCentipedeSwingStop(AHazePlayerCharacter Player, UHazeAudioEmitter HeadEmitter) {};

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Speed (Keep in sync with AnimInstanceSanctuaryCentipede)
		MioVelocity = FVector2D(Game::Mio.GetActorLocalVelocity().Y, Game::Mio.GetActorLocalVelocity().X);
		ZoeVelocity = FVector2D(Game::Zoe.GetActorLocalVelocity().Y, Game::Zoe.GetActorLocalVelocity().X);

		float X = 0.0;
		float Y_ = 0.0;
		FVector2D Previous;

		Audio::GetScreenPositionRelativePanningValue(MioHeadEmitter.AudioComponent.WorldLocation, Previous, X, Y_);
		MioHeadEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);

		Audio::GetScreenPositionRelativePanningValue(ZoeHeadEmitter.AudioComponent.WorldLocation, Previous, X, Y_);
		ZoeHeadEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);

		const FVector BodyMiddle = BodyMiddlePoint;
		DefaultEmitter.SetEmitterLocation(BodyMiddle);

		Audio::GetScreenPositionRelativePanningValue(BodyMiddle, Previous, X, Y_);
		DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);

		int AirborneIt = 0;
		for(auto& EmitterData : EmitterDatas)
		{
			if(!EmitterData.bWasGrounded && EmitterData.MoveComp.IsOnWalkableGround())
			{
				EmitterData.bWasGrounded = true;
				OnCentipedeHeadGroundedStart(EmitterData.Player, EmitterData.HeadEmitter);
				OnCentipedeLand(EmitterData.MoveComp.PreviousVerticalVelocity.Size());
			}
			else if(EmitterData.bWasGrounded && (!EmitterData.MoveComp.IsOnWalkableGround() && !EmitterData.SwingComp.IsBitingSwingPoint()))
			{
				EmitterData.bWasGrounded = false;	
				bool bBothHeadsAirborne = !GetOtherPlayerData(EmitterData).bWasGrounded;
				OnCentipedeHeadAirborneStart(EmitterData.Player, EmitterData.HeadEmitter, bBothHeadsAirborne);				
			}

			if(!EmitterData.bWasSwinging && EmitterData.SwingComp.IsBitingSwingPoint())
			{
				EmitterData.bWasSwinging = true;
				auto OtherPlayerData = GetOtherPlayerData(EmitterData);
				OnCentipedeSwingStart(OtherPlayerData.Player, OtherPlayerData.HeadEmitter);
			}
			else if(EmitterData.bWasSwinging && !EmitterData.SwingComp.IsBitingSwingPoint())
			{
				EmitterData.bWasSwinging = false;				
				auto OtherPlayerData = GetOtherPlayerData(EmitterData);
				if(!OtherPlayerData.SwingComp.IsBitingSwingPoint())
					OnCentipedeSwingStop(OtherPlayerData.Player, OtherPlayerData.HeadEmitter);
			}
		}
	}
}