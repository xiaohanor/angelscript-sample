class UPlayerHandSlideAudioCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Audio;

	UPlayerMovementAudioComponent MoveAudioComp;
	UPlayerFootstepTraceComponent TraceComp;
	UPlayerAudioMaterialComponent MaterialComp;

	TMap<EHandType, FName> HandToMaterialTag;
	default HandToMaterialTag.Add(EHandType::Left, NAME_None);
	default HandToMaterialTag.Add(EHandType::Right, NAME_None);

	TMap<EHandType, FName> HandToSlide;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
		TraceComp = UPlayerFootstepTraceComponent::Get(Player);
		MaterialComp = UPlayerAudioMaterialComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveAudioComp.CanPerformMovement(EMovementAudioFlags::HandTrace))
			return false;

		if(!MoveAudioComp.AnyHandSliding())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveAudioComp.CanPerformMovement(EMovementAudioFlags::HandTrace))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HandToMaterialTag[EHandType::Left] = NAME_None;
		HandToMaterialTag[EHandType::Right] = NAME_None;

		HandToSlide.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementAudioEventHandler::Trigger_StopHandSlideLoop(Player, FPlayerHandSlideAudioParams());

		QueryHandSlideDeactivation(EHandType::Left);
		QueryHandSlideDeactivation(EHandType::Right);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TMap<EHandType, FName> CurrentMaterials;
		GetCurrentMaterials(CurrentMaterials);

		QueryHandSlide(EHandType::Left, CurrentMaterials);		
		QueryHandSlide(EHandType::Right, CurrentMaterials);	

		HandToMaterialTag = CurrentMaterials;
	}

	void StartHandSlideForHand(const EHandType Hand, const FName MaterialTag)
	{
		FPlayerHandSlideAudioParams SlideParams;
		SlideParams.Hand = Hand;

		if(MaterialComp.GetMaterialEvent(MaterialTag, MovementAudio::Player::HAND_SLIDING_LOOP_TAG, EHandTraceAction::Plant, SlideParams.MaterialEvent))
		{
			UMovementAudioEventHandler::Trigger_StartHandSlideLoop(Player, SlideParams);
			
			FHandTraceData& HandData = TraceComp.GetTraceData(Hand);
			HandData.Trace.bIsSliding = true;

			HandToSlide.Add(Hand, MaterialTag);
		}
	}

	void StopHandSlideForHand(const EHandType Hand)
	{
		FPlayerHandSlideAudioParams SlideParams;	
		SlideParams.Hand = Hand;

		FHandTraceData& HandData = TraceComp.GetTraceData(Hand);
		HandData.Trace.bIsSliding = false;

		HandToSlide.Remove(Hand);
		MoveAudioComp.RemoveHandSliding(Hand);

		UMovementAudioEventHandler::Trigger_StopHandSlideLoop(Player, SlideParams);

		// Play stop slide oneshot
		FPlayerHandSlideAudioParams StopSlideParams;
		StopSlideParams.Hand = Hand;

		const float NormLinearSpeed = GetHandSlideIntensity(HandData);
		StopSlideParams.LinearSpeed = NormLinearSpeed;	

		if(MaterialComp.GetMaterialEvent(HandToMaterialTag[Hand], MovementAudio::Player::HAND_SLIDING_STOP_TAG, EHandTraceAction::Release, StopSlideParams.MaterialEvent))
			UMovementAudioEventHandler::Trigger_StopHandSlide(Player, StopSlideParams);				
	}

	private void GetCurrentMaterials(TMap<EHandType, FName>& OutTrackedMaterialTags)
	{
		FHandTraceData& LeftHandTraceData = TraceComp.GetTraceData(EHandType::Left);
		FHandTraceData& RightHandTraceData = TraceComp.GetTraceData(EHandType::Right);
		OutTrackedMaterialTags.Add(EHandType::Left, NAME_None);
		OutTrackedMaterialTags.Add(EHandType::Right, NAME_None);

		if(LeftHandTraceData.GroundedPhysMat != nullptr)
		{
			UPhysicalMaterialAudioAsset AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(LeftHandTraceData.GroundedPhysMat.AudioAsset);
			if (AudioPhysMat != nullptr)
				OutTrackedMaterialTags[EHandType::Left] = AudioPhysMat.FootstepData.FootstepTag;
		}

		if(RightHandTraceData.GroundedPhysMat != nullptr)
		{
			UPhysicalMaterialAudioAsset AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(RightHandTraceData.GroundedPhysMat.AudioAsset);
			if (AudioPhysMat != nullptr)
				OutTrackedMaterialTags[EHandType::Right] = AudioPhysMat.FootstepData.FootstepTag;
		}
	}

	private void QueryHandSlide(const EHandType HandType, const TMap<EHandType, FName> CurrentMaterials)
	{
		const FName CurrMaterial = CurrentMaterials[HandType];
		const FName PrevMaterial = HandToMaterialTag[HandType];
		FName TrackedHandLoopMaterial;

		const FName OtherHandCurrMaterial = CurrentMaterials[GetOtherHand(HandType)];

		FHandTraceData& HandData = TraceComp.GetTraceData(HandType);
		FHandTraceData& OtherHandData = TraceComp.GetTraceData(GetOtherHand(HandType));

		const bool bTrackingSliding = MoveAudioComp.IsHandSliding(HandType);

		if(!bTrackingSliding && HandData.Trace.bIsSliding)
		{
			StopHandSlideForHand(HandType);
			return;
		}
		else if(bTrackingSliding)
		{
			// Check if hand has a new material
			if(CurrMaterial != NAME_None)
			{	
				if(HandData.Trace.bIsSliding && CurrMaterial == PrevMaterial)
				{
					// Hand was already sliding and material hasn't changed, simply tick sliding and then bail
					FPlayerHandSlideTickParams TickParams;
					TickParams.Hand = HandType;

					const float NormLinearSpeed = GetHandSlideIntensity(HandData);
					TickParams.LinearSpeed = NormLinearSpeed;	

					auto AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(HandData.GroundedPhysMat.AudioAsset);
					TickParams.SlidePitchMin = AudioPhysMat.FootstepData.MinHandSlidePitchOffset;
					TickParams.SlidePitchMax = AudioPhysMat.FootstepData.MaxHandSlidePitchOffset;

					UMovementAudioEventHandler::Trigger_TickHandSlide(Player, TickParams);
					return;	
				}				
				
				HandToSlide.Find(GetOtherHand(HandType), TrackedHandLoopMaterial);

				if(OtherHandData.Trace.bIsSliding && CurrMaterial == TrackedHandLoopMaterial)
					return;
				
				// If this is the start of a new slide sequence, play start oneshot
				if(!HandData.Trace.bIsSliding)
				{
					FPlayerHandSlideAudioParams StartSlideParams;

					StartSlideParams.Hand = HandType;

					const float NormLinearSpeed = GetHandSlideIntensity(HandData);
					StartSlideParams.LinearSpeed = NormLinearSpeed;	

					if(MaterialComp.GetMaterialEvent(CurrMaterial, MovementAudio::Player::HAND_SLIDING_START_TAG, EHandTraceAction::Plant, StartSlideParams.MaterialEvent))
						UMovementAudioEventHandler::Trigger_StartHandSlide(Player, StartSlideParams);
				}
				
				// Hand has transitioned into a new material, play it alongside the other hand material				
				StartHandSlideForHand(HandType, CurrMaterial);
			}
			else if(HandToSlide.Find(HandType, TrackedHandLoopMaterial))
			{
				// Has stopped sliding?	

				// Hand was sliding on a different material than the other, so stop it now
				const bool bSharingMaterial = TrackedHandLoopMaterial == OtherHandCurrMaterial; 
			
				if(!bSharingMaterial)
				{
					StopHandSlideForHand(HandType);		
				}
				// Hand was sliding on same material as the other, update MaterialtoHandTag to make sure it's now tracking the correct hand
				else if(OtherHandData.Trace.bIsSliding)
				{				
					HandToSlide.Add(GetOtherHand(HandType), TrackedHandLoopMaterial);
				}				
			}
		}
	}

	private void QueryHandSlideDeactivation(const EHandType Hand)
	{
		if(!MoveAudioComp.IsHandSliding(Hand))
			return;

		FName TrackedMaterial = NAME_None;
		if(HandToMaterialTag.Find(Hand, TrackedMaterial) && TrackedMaterial != NAME_None)
		{
			FHandTraceData& TraceData = TraceComp.GetTraceData(Hand);

			FPlayerHandSlideAudioParams StopSlideParams;
			StopSlideParams.Hand = Hand;

			const float NormLinearSpeed = GetHandSlideIntensity(TraceData);
			StopSlideParams.LinearSpeed = NormLinearSpeed;	

			if(MaterialComp.GetMaterialEvent(TrackedMaterial, MovementAudio::Player::HAND_SLIDING_STOP_TAG, EHandTraceAction::Release, StopSlideParams.MaterialEvent))
				UMovementAudioEventHandler::Trigger_StopHandSlide(Player, StopSlideParams);		

			MoveAudioComp.RemoveHandSliding(Hand);		
		}
	}

	private float GetHandSlideIntensity(const FHandTraceData& HandTraceData)
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0.0, MovementAudio::Player::MAX_HAND_SLIDE_VELO_SPEED), FVector2D(0.0, 2.0), HandTraceData.VeloSpeed);
	}

	private EHandType GetOtherHand(const EHandType InHand)
	{
		if(InHand == EHandType::Left)
			return EHandType::Right;
		else if(InHand == EHandType::Right)
			return EHandType::Left;

		return EHandType::None;
	}

}