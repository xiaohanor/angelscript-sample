// USTRUCT()
// struct FFootstepTagEvents
// {
// 	UPROPERTY(EditDefaultsOnly)
// 	UHazeAudioEvent Left = nullptr;

// 	UPROPERTY(EditDefaultsOnly)
// 	UHazeAudioEvent Right = nullptr;
// }

// USTRUCT()
// struct FHandTagEvents
// {
// 	UPROPERTY(EditDefaultsOnly)
// 	UHazeAudioEvent Left = nullptr;

// 	UPROPERTY(EditDefaultsOnly)
// 	UHazeAudioEvent Right = nullptr;
// }

UCLASS(Abstract)
class UPlayer_Movement_Basic_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Left(FPlayerFootstepParams FootstepParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Right(FPlayerFootstepParams FootstepParams){}

	UFUNCTION(BlueprintEvent)
	void OnHandTrace_Left(FPlayerHandImpactParams ImpactParams){}

	UFUNCTION(BlueprintEvent)
	void OnHandTrace_Right(FPlayerHandImpactParams ImpactParams){}

	UFUNCTION(BlueprintEvent)
	void StartHandSlideLoop(FPlayerHandSlideAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void StopHandSlideLoop(FPlayerHandSlideAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void StartFootSlideLoop(FPlayerFootSlideStartAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void StopFootSlideLoop(){}

	UFUNCTION(BlueprintEvent)
	void StartFootSlide(FPlayerFootSlideStartAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void StopFootSlide(FPlayerFootSlideStopAudioParams SlideParams){}

	UFUNCTION(BlueprintEvent)
	void TickFootSlide(FPlayerFootSlideTickParams TickParams){}

	UFUNCTION(BlueprintEvent)
	void TickHandSlide(FPlayerHandSlideTickParams TickParams){}

	UFUNCTION(BlueprintEvent)
	void StartArmswing(){}

	UFUNCTION(BlueprintEvent)
	void StopArmswing(){}

	UFUNCTION(BlueprintEvent)
	void StopHandSlide(FPlayerHandSlideAudioParams StopParams){}

	UFUNCTION(BlueprintEvent)
	void StartHandSlide(FPlayerHandSlideAudioParams StartParams){}

	/* END OF AUTO-GENERATED CODE */

	// Fallback AudioPhysMat to use if no valid material could be set
	UPROPERTY(Category = "Material", meta = (GetOptions = GetMaterialNames))
	FName DefaultMaterial = n"Default";

	UPROPERTY(BlueprintReadWrite, Category = "Sliding")
	FHazeAudioPostEventInstance FootSlideLoopEventInstance;

	UPROPERTY(BlueprintReadWrite, Category = "Sliding")
	FHazeAudioPostEventInstance LeftHandSlideLoopEventInstance;

	UPROPERTY(BlueprintReadWrite, Category = "Sliding")
	FHazeAudioPostEventInstance RightHandSlideLoopEventInstance;

	UPROPERTY(BlueprintReadWrite, Category = "Armswing")
	FHazeAudioPostEventInstance ArmswingArmLoopEventInstance;	

	private FHazeArmswingAudioEvents ArmswingEvents;

	FName PlayerName;
	FName VariantTypeName;

	const float MAX_ELEVATION_DELTA_RANGE = 15;
	float LastElevationPos = 0;

#if EDITOR
	UFUNCTION()
	TArray<FString> GetMaterialNames() const
	{
		TArray<FString> HandTagsAsString;

		TArray<FAssetData> PhysMatDatas;
		AssetRegistry::GetAssetsByClass(FTopLevelAssetPath(UPhysicalMaterialAudioAsset), PhysMatDatas);

		for(auto AssetData : PhysMatDatas)
		{
			FString _;
			FString MaterialName;

			AssetData.AssetName.ToString().Split("_", _, MaterialName);
			HandTagsAsString.AddUnique(MaterialName);			
		}
	
		return HandTagsAsString;
	}

#endif

	UPlayerFootstepTraceComponent TraceComp;
	UPlayerMovementComponent MoveComp;
	UPlayerMovementAudioComponent MoveAudioComp;
	UPlayerAudioMaterialComponent MaterialComp;

	private FName LastFootMovementTag = NAME_None;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MoveComp = UPlayerMovementComponent::Get(PlayerOwner);
		TraceComp = UPlayerFootstepTraceComponent::GetOrCreate(PlayerOwner);
		MoveAudioComp = UPlayerMovementAudioComponent::Get(PlayerOwner);
		MaterialComp = UPlayerAudioMaterialComponent::Get(PlayerOwner);

		// Get armswing events for player variant
		UPlayerVariantComponent VariantComp = UPlayerVariantComponent::Get(PlayerOwner);
		ArmswingEvents = VariantComp.GetPlayerVariantArmswingEvents(PlayerOwner);		
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
	bool IsInAir()
	{
		return !MoveComp.IsOnAnyGround();
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
		return ArmswingEvents.ArmLoopEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Arm Move Event")
	UHazeAudioEvent GetArmswingArmMoveEvent()
	{
		return ArmswingEvents.ArmMoveEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Jump Event")
	UHazeAudioEvent GetArmswingJumpEvent()
	{
		return ArmswingEvents.JumpEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Land Low Intensity Event")
	UHazeAudioEvent GetArmswingLandLowIntEvent()
	{
		return ArmswingEvents.LandLowIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Land High Intensity Event")
	UHazeAudioEvent GetArmswingLandHighIntEvent()
	{
		return ArmswingEvents.LandHighIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Roll Low Intensity Event")
	UHazeAudioEvent GetArmswingRollLowIntEvent()
	{
		return ArmswingEvents.RollLowIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Roll Medium Intensity Event")
	UHazeAudioEvent GetArmswingRollMedIntEvent()
	{
		return ArmswingEvents.RollMediumIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Roll High Intensity Event")
	UHazeAudioEvent GetArmswingRollHighIntEvent()
	{
		return ArmswingEvents.RollHighIntEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Stand to Crouch Event")
	UHazeAudioEvent GetArmswingStandToCrouchEvent()
	{
		return ArmswingEvents.StandToCrouchEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Crouch to Stand Event")
	UHazeAudioEvent GetArmswingCrouchToStandEvent()
	{
		return ArmswingEvents.CrouchToStandEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Slide Event")
	UHazeAudioEvent GetArmswingSlideEvent()
	{
		return ArmswingEvents.SlideLoopEvent;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Armswing Fall Event")
	UHazeAudioEvent GetArmswingFallEvent()
	{
		return ArmswingEvents.FallLoopEvent;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void PostCompiled()
	{
		SoundDefEditor::CachePlayerMovementSoundDefMaterialEvents(this);
	}
#endif

	UFUNCTION()
	void FoliageOverlapEvent(FFoliageDetectionData Data)
	{
		if (TraceComp == nullptr)
			return;

		TraceComp.OnFoliageMaterialOverride(Data.MaterialOverride);
	}

	UFUNCTION(BlueprintOverride)
	bool GetScriptImplementedTriggerEffectEvents(
												 UHazeEffectEventHandlerComponent& EventHandlerComponent,
												 TMap<FName,TSubclassOf<UHazeEffectEventHandler>>& EventClassAndFunctionNames) const
	{
		EventClassAndFunctionNames.Add(n"FoliageOverlapEvent", UFoliageDetectionEventHandler);

		return true;
	}

}
