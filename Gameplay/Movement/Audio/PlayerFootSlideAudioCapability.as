struct FAudioFootSlideActivationParams
{
	bool bIsLadderSlide = false;
	bool bIsPoleSlide = false;

	float MakeUpGain = 0.0;
	float Pitch = 0.0;
}

class UPlayerFootSlideAudioCapability : UHazePlayerCapability
{
	UPlayerMovementAudioComponent MoveAudioComp;
	UPlayerSlideComponent SlideComp;
	UPlayerLadderComponent LadderComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerMovementComponent MoveComp;
	UPlayerAudioMaterialComponent MaterialComp;

	FName TrackedMaterialTag = NAME_None;

	const FName SLIDING_START_TAG = n"Slide_Start";
	const FName SLIDING_STOP_TAG = n"Slide_Stop";
	const FName SLIDING_LOOP_TAG = n"Slide_Loop";

	const float MAX_LINEAR_SLIDING_SPEED = 750.0;
	const float MIN_VELOCITY_THRESHOLD = 5.0;

	// static slide type value offsets
	const float LADDER_SLIDE_GAIN = -9.0;
	const float LADDER_SLIDE_PITCH = 100;

	const float POLE_CLIMB_SLIDE_GAIN = -9.0;
	const float POLE_CLIMN_SLIDE_PITCH = 100;

	bool bIsLadderSlide = false;
	bool bIsPoleClimbSlide = false;
	float SlideGain = 0.0;
	float SlidePitch = 0.0;

	FVector LastVelo;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
		LadderComp = UPlayerLadderComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		MoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
		MaterialComp = UPlayerAudioMaterialComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAudioFootSlideActivationParams& Params) const
	{
		if(SlideComp.IsSlideActive())
			return true;

		if(LadderComp.AnimData.State == EPlayerLadderState::ClimbDown)
		{
			Params.bIsLadderSlide = true;
			Params.MakeUpGain = LADDER_SLIDE_GAIN;
			Params.Pitch = LADDER_SLIDE_PITCH;

			return true;
		}

		if(PoleClimbComp.AnimData.bSliding && !MoveComp.HasGroundContact())
		{
			Params.bIsPoleSlide = true;
			Params.MakeUpGain = POLE_CLIMB_SLIDE_GAIN;
			Params.Pitch = POLE_CLIMN_SLIDE_PITCH;

			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.HasMovedThisFrame())
			return true;

		if(SlideComp.IsSlideActive())
			return false;

		if(bIsLadderSlide && LadderComp.AnimData.State == EPlayerLadderState::ClimbDown)
			return false;

		if(bIsPoleClimbSlide && PoleClimbComp.AnimData.bSliding)
			return false;	

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAudioFootSlideActivationParams Params)
	{
		TrackedMaterialTag = NAME_None;
		bIsLadderSlide = Params.bIsLadderSlide;
		bIsPoleClimbSlide = Params.bIsPoleSlide;
		SlideGain = Params.MakeUpGain;
		SlidePitch = Params.Pitch;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(TrackedMaterialTag != NAME_None)
		{
			FPlayerFootSlideStopAudioParams StopParams;

			const float Speed = MoveComp.GetVelocity().Size();
			StopParams.LinearSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_LINEAR_SLIDING_SPEED), FVector2D(0.0, 2.0), Speed);	
			if(MaterialComp.GetMaterialEvent(TrackedMaterialTag, SLIDING_STOP_TAG, EFootType::None, EFootType::Release, StopParams.MaterialEvent))
				UMovementAudioEventHandler::Trigger_StopFootSlide(Player, StopParams);

		}

		UMovementAudioEventHandler::Trigger_StopFootSlideLoop(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FName CurrentMaterialTag = NAME_None;
		if(QueryMaterial(CurrentMaterialTag) )
		{
			if(CurrentMaterialTag != TrackedMaterialTag)
			{
				if(TrackedMaterialTag != NAME_None)
				{
					UMovementAudioEventHandler::Trigger_StopFootSlideLoop(Player);
				}
				else
				{
					FPlayerFootSlideStartAudioParams StartParams;
					StartParams.MakeUpGain = SlideGain;
					StartParams.Pitch = SlidePitch;

					if(MaterialComp.GetMaterialEvent(CurrentMaterialTag, SLIDING_START_TAG, EFootType::None, EFootType::Left, StartParams.MaterialEvent))
					{
						const float Speed = MoveComp.Velocity.Size();
						StartParams.LinearSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_LINEAR_SLIDING_SPEED), FVector2D(0.0, 2.0), Speed);		
						UMovementAudioEventHandler::Trigger_StartFootSlide(Player, StartParams);
					}
				}

				TrackedMaterialTag = CurrentMaterialTag;
				FPlayerFootSlideStartAudioParams SlideParams;
				SlideParams.MakeUpGain = SlideGain;
				SlideParams.Pitch = SlidePitch;

				if(MaterialComp.GetMaterialEvent(CurrentMaterialTag, SLIDING_LOOP_TAG, EFootType::None, EFootType::Left, SlideParams.MaterialEvent))
				{
					UMovementAudioEventHandler::Trigger_StartFootSlideLoop(Player, SlideParams);
				}
			}

			FPlayerFootSlideTickParams TickParams;
			SetIntensityValues(TickParams);

			UMovementAudioEventHandler::Trigger_TickFootSlide(Player, TickParams);
		}
		else if(TrackedMaterialTag != NAME_None)
		{
			FPlayerFootSlideStopAudioParams StopParams;
			if(MaterialComp.GetMaterialEvent(TrackedMaterialTag, SLIDING_STOP_TAG, EFootType::None, EFootType::Release, StopParams.MaterialEvent))
			{
				const float Speed = MoveComp.Velocity.Size();
				StopParams.LinearSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_LINEAR_SLIDING_SPEED), FVector2D(0.0, 2.0), Speed);	

				UMovementAudioEventHandler::Trigger_StopFootSlide(Player, StopParams);
			}

			TrackedMaterialTag = NAME_None;
			UMovementAudioEventHandler::Trigger_StopFootSlideLoop(Player);
		}

		LastVelo = MoveComp.Velocity.GetSafeNormal();
	}

	private bool QueryMaterial(FName& OutMaterialTag)
	{
		FHazeTraceSettings Trace = FHazeTraceSettings();
		Trace.TraceWithChannel(ECollisionChannel::AudioTrace);
		Trace.UseLine();		

		//Trace.DebugDrawOneFrame();

		FVector TraceStart;	
		FVector TraceEnd;

		if(!bIsLadderSlide && !bIsPoleClimbSlide)
		{			
			TraceStart = Player.GetActorCenterLocation();

			FVector SlideDir =  Player.GetActorVelocity().GetSafeNormal();
			if(SlideDir.IsZero())
				return false;

			FVector TraceDir = (SlideDir - Player.ActorUpVector).GetSafeNormal();	
			TraceEnd = TraceStart + TraceDir * 100;
		}
		else
		{	
			TraceStart = GetTraceStartPos();
			FVector TraceDir = Player.ActorForwardVector;
			TraceEnd = TraceStart + TraceDir * 100;
		}

		// Shouldn't really happen
		if((TraceEnd - TraceStart).IsNearlyZero())
			return false;

		FHitResult Result = Trace.QueryTraceSingle(TraceStart, TraceEnd);
		
		if (MoveAudioComp.OnFootSlideTrace.IsBound())
			MoveAudioComp.OnFootSlideTrace.Broadcast(TraceStart, TraceEnd);
		
		if(!Result.bBlockingHit)
			return false;

		UPhysicalMaterial ContactPhysMat = AudioTrace::GetPhysMaterialFromHit(Result, Trace);

		if(ContactPhysMat == nullptr)
			return false;

		UPhysicalMaterialAudioAsset AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(ContactPhysMat.AudioAsset);			
		OutMaterialTag = AudioPhysMat.FootstepData.FootstepTag;	

		return true;
	}

	void SetIntensityValues(FPlayerFootSlideTickParams& TickParams)
	{
		const float Speed = MoveComp.Velocity.Size();
		TickParams.LinearSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_LINEAR_SLIDING_SPEED), FVector2D(0.0, 2.0), Speed);

		float AngularVelo = 1 - MoveComp.Velocity.GetSafeNormal().DotProduct(LastVelo);
		TickParams.AngularSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.00025), FVector2D(0.0, 2.0), AngularVelo);	
	}

	FVector GetTraceStartPos()
	{
		const FVector LeftFootPos = Player.Mesh.GetSocketLocation(MovementAudio::Player::LeftFootBoneName);

		//const FVector RightFootPos = Player.Mesh.GetSocketLocation(MovementAudio::Player::RightFootBoneName);
		//const FVector FootBetweenPos = Math::Lerp(LeftFootPos, RightFootPos, 0.5);
		return LeftFootPos;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		auto Log = TEMPORAL_LOG(Player, "Audio/Foot/Slide");

		if(MaterialComp.CheckMovementOverrideMaterialTag(EFootType::None, TrackedMaterialTag))
		{
			TrackedMaterialTag = FName(f"{TrackedMaterialTag} (MATERIAL OVERRIDE)");
		}

		Log.Value("PhysMat", TrackedMaterialTag);
		Log.Value("Velo", LastVelo.Size());
	}
}