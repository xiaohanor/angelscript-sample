USTRUCT()
struct FPlayerAddativeFootstepEventData
{

}

UCLASS(Abstract)
class UPlayer_Movement_Addative_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TickHandSlide(FPlayerHandSlideTickParams TickParams){}

	UFUNCTION(BlueprintEvent)
	void StopHandSlideLoop(FPlayerHandSlideAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void StartHandSlideLoop(FPlayerHandSlideAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void StopHandSlide(FPlayerHandSlideAudioParams StopParams){}

	UFUNCTION(BlueprintEvent)
	void OnHandTrace_Right(FPlayerHandImpactParams ImpactParams){}

	UFUNCTION(BlueprintEvent)
	void OnHandTrace_Left(FPlayerHandImpactParams ImpactParams){}

	UFUNCTION(BlueprintEvent)
	void TickFootSlide(FPlayerFootSlideTickParams TickParams){}

	UFUNCTION(BlueprintEvent)
	void StopFootSlideLoop(){}

	UFUNCTION(BlueprintEvent)
	void StartFootSlideLoop(FPlayerFootSlideStartAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void StopFootSlide(FPlayerFootSlideStopAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void StartFootSlide(FPlayerFootSlideStartAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Right(FPlayerFootstepParams FootstepParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Left(FPlayerFootstepParams FootstepParams){}

	UFUNCTION(BlueprintEvent)
	void StopArmswing(){}

	UFUNCTION(BlueprintEvent)
	void StartArmswing(){}

	UFUNCTION(BlueprintEvent)
	void StartHandSlide(FPlayerHandSlideAudioParams StartParams){}

	/* END OF AUTO-GENERATED CODE */
	
	UFootstepTraceComponent TraceComp;
	UPlayerMovementAudioComponent MoveAudioComp;

	UPROPERTY(EditDefaultsOnly, Category = Armswing)
	FHazeArmswingAudioEvents AddativeArmswingEvents;

	UPROPERTY(EditDefaultsOnly, Category = Foot, Meta = (GetOptions = GetFootstepTags))
	TMap<FName, UHazeAudioEvent> PlantFootstepTagEvents;
	UPROPERTY(EditDefaultsOnly, Category = Foot, Meta = (GetOptions = GetFootstepTags))
	TMap<FName, UHazeAudioEvent> ReleaseFootstepTagEvents;

	UPROPERTY(EditDefaultsOnly, Category = Hand, Meta = (GetOptions = GetHandTags))
	TMap<FName, UHazeAudioEvent> PlantHandTagEvents;
	UPROPERTY(EditDefaultsOnly, Category = Hand, Meta = (GetOptions = GetHandTags))
	TMap<FName, UHazeAudioEvent> ReleaseHandTagEvents;

	const float MAX_ELEVATION_DELTA_RANGE = 15;
	float LastElevationPos = 0;

	const FName PLAYER_FOOT_GROUP = n"Player_Foot";
	const FName PLAYER_HAND_GROUP = n"Player_Hand";

	#if EDITOR
	UFUNCTION()
	TArray<FString> GetFootstepTags() const
	{
		TArray<FString> FootstepTags;

		UHazeMovementAudioTagsAsset TagsAsset = Cast<UHazeMovementAudioTagsAsset>(LoadObject(nullptr, "/Game/Core/Audio/DA_MovementAudioTags"));
		FMovementAudioTagsGroup TagsGroup;

		TagsAsset.MovementTagsGroups.Find(PLAYER_FOOT_GROUP, TagsGroup);	

		for(auto& NameTag : TagsGroup.Tags)
		{
			FootstepTags.Add(NameTag.ToString());
		}

		return FootstepTags;
	}	
	UFUNCTION()
	TArray<FString> GetHandTags() const
	{
		TArray<FString> HandTags;

		UHazeMovementAudioTagsAsset TagsAsset = Cast<UHazeMovementAudioTagsAsset>(LoadObject(nullptr, "/Game/Core/Audio/DA_MovementAudioTags"));
		FMovementAudioTagsGroup TagsGroup;

		TagsAsset.MovementTagsGroups.Find(PLAYER_HAND_GROUP, TagsGroup);	

		for(auto& NameTag : TagsGroup.Tags)
		{
			HandTags.Add(NameTag.ToString());
		}

		return HandTags;
	}	
	#endif

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TraceComp = UFootstepTraceComponent::GetOrCreate(PlayerOwner);
		MoveAudioComp = UPlayerMovementAudioComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return !MoveAudioComp.IsDefaultMovementBlocked();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return MoveAudioComp.IsDefaultMovementBlocked();
	}

	UFUNCTION(BlueprintPure, meta = (DisplayName = "Left Arm Velocity"))
	float GetLeftArmVelocity()
	{
		return MoveAudioComp.GetHandVeloSpeed(EHandType::Left);		
	}

	UFUNCTION(BlueprintPure, meta = (DisplayName = "Right Arm Velocity"))
	float GetRightArmVelocity()
	{
		return MoveAudioComp.GetHandVeloSpeed(EHandType::Right);
	}

	UFUNCTION(BlueprintPure, meta = (DisplayName = "Combined Arm Velocity"))
	float GetCombinedArmVelocityAvg()
	{
		return (GetLeftArmVelocity() + GetRightArmVelocity()) / 2;
	}
	
	UFUNCTION(BlueprintPure)
	bool IsArmSwingActive()
	{
		return MoveAudioComp.CanPerformMovement(EMovementAudioFlags::Armswing);
	}

	UFUNCTION(BlueprintPure)
	float GetElevationDeltaNormalized()
	{
		const float CurrElevation = DefaultEmitter.GetAudioComponent().GetWorldLocation().Z;
		const float ElevationDelta = CurrElevation - LastElevationPos;

		const float DeltaSign = Math::Sign(ElevationDelta);

		float ElevationDeltaNormalized = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_ELEVATION_DELTA_RANGE), FVector2D(0.0, 1.0), Math::Abs(ElevationDelta));
		ElevationDeltaNormalized *= DeltaSign;

		LastElevationPos = CurrElevation;

		return ElevationDeltaNormalized;
	}

	// Armswing Event Getters
	UFUNCTION(BlueprintPure, DisplayName = "Armswing Arm Loop Event")
	UHazeAudioEvent GetArmswingArmLoopEvent()
	{
		return AddativeArmswingEvents.ArmLoopEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Arm Move Event")
	UHazeAudioEvent GetArmswingArmMoveEvent()
	{
		return AddativeArmswingEvents.ArmMoveEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Jump Event")
	UHazeAudioEvent GetArmswingJumpEvent()
	{
		return AddativeArmswingEvents.JumpEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Land Low Intensity Event")
	UHazeAudioEvent GetArmswingLandLowIntEvent()
	{
		return AddativeArmswingEvents.LandLowIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Land High Intensity Event")
	UHazeAudioEvent GetArmswingLandHighIntEvent()
	{
		return AddativeArmswingEvents.LandHighIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Roll Low Intensity Event")
	UHazeAudioEvent GetArmswingRollLowIntEvent()
	{
		return AddativeArmswingEvents.RollLowIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Roll Medium Intensity Event")
	UHazeAudioEvent GetArmswingRollMedIntEvent()
	{
		return AddativeArmswingEvents.RollMediumIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Roll High Intensity Event")
	UHazeAudioEvent GetArmswingRollHighIntEvent()
	{
		return AddativeArmswingEvents.RollHighIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Stand to Crouch Event")
	UHazeAudioEvent GetArmswingStandToCrouchEvent()
	{
		return AddativeArmswingEvents.StandToCrouchEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Crouch to Stand Event")
	UHazeAudioEvent GetArmswingCrouchToStandEvent()
	{
		return AddativeArmswingEvents.CrouchToStandEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Slide Event")
	UHazeAudioEvent GetArmswingSlideEvent()
	{
		return AddativeArmswingEvents.SlideLoopEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Fall Event")
	UHazeAudioEvent GetArmswingFallEvent()
	{
		return AddativeArmswingEvents.FallLoopEvent;
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetAddativeFootstepEvent(bool bIsPlant)
	{
		UHazeAudioEvent AddEvent = nullptr;
		if(bIsPlant)		
			PlantFootstepTagEvents.Find(MoveAudioComp.GetActiveMovementTag(PLAYER_FOOT_GROUP), AddEvent);
		else
			ReleaseFootstepTagEvents.Find(MoveAudioComp.GetActiveMovementTag(PLAYER_FOOT_GROUP), AddEvent);

		return AddEvent;
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetAddativeHandEvent(bool bIsPlant)
	{
		UHazeAudioEvent AddEvent = nullptr;
		if(bIsPlant)		
			PlantHandTagEvents.Find(MoveAudioComp.GetActiveMovementTag(PLAYER_HAND_GROUP), AddEvent);
		else
			ReleaseHandTagEvents.Find(MoveAudioComp.GetActiveMovementTag(PLAYER_HAND_GROUP), AddEvent);

		return AddEvent;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		#if EDITOR
		auto FootLog = TEMPORAL_LOG(PlayerOwner, "Audio/Foot");
		FootLog.Value("Addative Movement SoundDef: ", GetName());
		auto ArmswingLog = TEMPORAL_LOG(PlayerOwner, "Audio/Armswing");
		ArmswingLog.Value("Addative Movement SoundDef: ", GetName());
		#endif
		
	}
}