class UPlayerHandTraceTemporalLogExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Player Hand Trace Temporal Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
	#if EDITOR
		auto Capability = Cast<UPlayerAudioHandTraceCapability>(Report.AssociatedObject);
		return Capability != nullptr;
	#else
		return false;
	#endif
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{	
		FHazeImmediateSectionHandle Section = Drawer.Begin();
		FHazeImmediateHorizontalBoxHandle Box = Section.HorizontalBox();	
		if(Box.Button("Toggle Debug"))
		{
			auto Capability = Cast<UPlayerAudioHandTraceCapability>(Report.AssociatedObject);
			if(Capability != nullptr)
			{
				Capability.bDebugActive = !Capability.bDebugActive;
			}
		}		
	}
}

class UPlayerAudioHandTraceCapability : UHazePlayerCapability
{
	default DebugCategory = n"Audio";
	default TickGroup = EHazeTickGroup::Audio;

	UPlayerMovementComponent MoveComp;
	UPlayerMovementAudioComponent AudioMoveComp;
	UPlayerAudioMaterialComponent MaterialComp;
	UPlayerFootstepTraceComponent TraceComp;

	const EFootstepTraceType TraceType = EFootstepTraceType::Sphere;

	// const float MIN_REQUIRED_HAND_VELO_DISTANCE = 5.0;

	// const float MIN_TRACE_LENGTH = 1.0;
	// const float MAX_TRACE_LENGTH = 5.0;

	// // Time hand must have been grounded before a slide can occur
	// float SlidingDelaySeconds = 0.10;
	
	const FName MOVEMENT_GROUP_NAME = n"Player_Hands";

	TMap<EHandType, FVector> TrackedHandLocations;
	TMap<EHandType, FVector> TrackedHandContactActorLocations;
	FVector CachedPlayerLocation;

	// // Distance in CM the hand moves between two frames at its maxium (I.e when sprinting) 
	// UPROPERTY()
	// float MaxHandVelocity = 30.0;

	// // Time in seconds that needs to pass before the individual hand can trigger again
	// UPROPERTY()
	// float PerHandTriggerCooldown = 0.25;

	FHandTrace LeftHandTrace;
	FHandTrace RightHandTrace;

	bool bDebugActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Player);
		MaterialComp = UPlayerAudioMaterialComponent::Get(Player);
		TraceComp = UPlayerFootstepTraceComponent::Get(Player);

		FHandTraceData& LeftHandTraceData = TraceComp.GetTraceData(EHandType::Left);
		LeftHandTraceData.Hand = EHandType::Left;
		LeftHandTraceData.Trace = LeftHandTrace;

		FHandTraceData& RightHandTraceData = TraceComp.GetTraceData(EHandType::Right);
		RightHandTraceData.Hand = EHandType::Right;
		RightHandTraceData.Trace = RightHandTrace;

		#if EDITOR
		TemporalLog::RegisterExtender(this, Player, f"Audio/Hand", n"PlayerHandTraceTemporalLogExtender", );
		#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AudioMoveComp.CanPerformMovement(EMovementAudioFlags::HandTrace))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AudioMoveComp.CanPerformMovement(EMovementAudioFlags::HandTrace))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FHandTraceData& LeftHandTraceData = TraceComp.GetTraceData(EHandType::Left);

		LeftHandTraceData.PlantTriggerTimeStamp = LeftHandTraceData.Settings.TriggerCooldown;
		LeftHandTraceData.ReleaseTriggerTimeStamp = LeftHandTraceData.Settings.TriggerCooldown;
		LeftHandTraceData.Trace.bGrounded = false;
		LeftHandTraceData.Trace.bIsSliding = false;
		LeftHandTraceData.Trace.bPerformed = false;
		LeftHandTraceData.GroundedPhysMat = nullptr;

		FHandTraceData& RightHandTraceData = TraceComp.GetTraceData(EHandType::Right);

		RightHandTraceData.PlantTriggerTimeStamp = RightHandTraceData.Settings.TriggerCooldown;
		RightHandTraceData.ReleaseTriggerTimeStamp = RightHandTraceData.Settings.TriggerCooldown;
		RightHandTraceData.Trace.bGrounded = false;
		RightHandTraceData.Trace.bIsSliding = false;
		RightHandTraceData.Trace.bPerformed = false;
		RightHandTraceData.GroundedPhysMat = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHandTraceData& LeftHandTraceData = TraceComp.GetTraceData(EHandType::Left);
		FHandTraceData& RightHandTraceData = TraceComp.GetTraceData(EHandType::Right);

		// Left
		QueryHandTrace(LeftHandTraceData, DeltaTime);

		// Right
		QueryHandTrace(RightHandTraceData, DeltaTime);

		if(bDebugActive)
		{
			#if EDITOR
			if(LeftHandTraceData.Trace.bIsSliding)
			{
				Debug::DrawDebugLine(LeftHandTraceData.Start, LeftHandTraceData.Trace.DEBUG_SlideStartLocation, FLinearColor::Blue);
			}
			if(RightHandTraceData.Trace.bIsSliding)
			{
				Debug::DrawDebugLine(RightHandTraceData.Start, RightHandTraceData.Trace.DEBUG_SlideStartLocation, FLinearColor::Blue);
			}
			#endif
		}

		TrackedHandLocations.FindOrAdd(EHandType::Left) = LeftHandTraceData.Start;
		TrackedHandLocations.FindOrAdd(EHandType::Right) = RightHandTraceData.Start;
		CachedPlayerLocation = Player.ActorLocation;

		if(LeftHandTraceData.ContactActor != nullptr)
			TrackedHandContactActorLocations.FindOrAdd(EHandType::Left) = LeftHandTraceData.ContactActor.ActorLocation;

		if(RightHandTraceData.ContactActor != nullptr)
			TrackedHandContactActorLocations.FindOrAdd(EHandType::Right) = RightHandTraceData.ContactActor.ActorLocation;

	}

	private void QueryHandTrace(FHandTraceData& InHandTraceData, const float DeltaTime)
	{
		if(EvaluateTrace(InHandTraceData, DeltaTime))
		{		
			// Trace was perfomed and was blocking

			if(!InHandTraceData.Trace.bGrounded)
			{
				// New hit was blocking while last wasn't - perform hand impact
				InHandTraceData.Trace.bGrounded = true;			
				
				PerformHandAction(InHandTraceData, EHandTraceAction::Plant);
				InHandTraceData.Trace.GroundedTimestamp = Time::GetGameTimeSeconds();					
			}	
			else if(!AudioMoveComp.IsHandSliding(InHandTraceData.Hand) && CanStartSliding(InHandTraceData))
			{	
				PerformHandAction(InHandTraceData, EHandTraceAction::StartSlide);

				#if EDITOR
					InHandTraceData.Trace.DEBUG_SlideStartLocation = InHandTraceData.Hit.ImpactPoint;
				#endif
			}	
		}
		else
		{	
			if(AudioMoveComp.IsHandSliding(InHandTraceData.Hand))
			{	
				PerformHandAction(InHandTraceData, EHandTraceAction::StopSlide);
			}	

			if(InHandTraceData.bValidFrameVelo)
			{
				// Trace was performed but was not blocking
				InHandTraceData.ContactActor = nullptr;
				InHandTraceData.ContactActorVelocity = FVector::ZeroVector;

				// Non-blocking hit - allow for new hand impact to be performed on next hit
				const bool bWasGrounded = InHandTraceData.Trace.bGrounded;
				InHandTraceData.Trace.bGrounded = false;

				// Last check was grounded, perform Release if velocity is valid
				if(bWasGrounded)
				{
					PerformHandAction(InHandTraceData, EHandTraceAction::Release);	
				}
			}
		}	
	}

	private bool EvaluateTrace(FHandTraceData& InHandTraceData, const float DeltaTime)
	{
		// Reset performed-flag
		InHandTraceData.Trace.bPerformed = false;

		// Get trace bounds from hand
		InHandTraceData.Start = GetTraceFrameStartPos(InHandTraceData);

		// If hand hasn't moved, invalidate hand trace for this frame and then bail
		if(!ValidateHandFrameVelo(InHandTraceData, DeltaTime))
			return false;	

		// Get Hand Trace Length	
		InHandTraceData.ScaledTraceLength = Math::Lerp(InHandTraceData.Settings.MinLength, InHandTraceData.Settings.MaxLength, Math::Clamp(InHandTraceData.VeloSpeed / InHandTraceData.Settings.MaxVelo, 0.0, 1.0));	
		InHandTraceData.End = GetTraceFrameEndPos(InHandTraceData);	
	
		return TraceComp.PerformHandTrace_Sphere(InHandTraceData, InHandTraceData.Settings.SphereRadius, bDebug = bDebugActive);							
	}

	private FHandTraceData& GetOtherHandData(const FHandTraceData& InHandData)
	{
		if(InHandData.Hand == EHandType::Left)
			return TraceComp.GetTraceData(EHandType::Right);
		
		return TraceComp.GetTraceData(EHandType::Left);
	}

	private void PerformHandAction(FHandTraceData& TraceData, const EHandTraceAction& Action)
	{
		FPlayerHandImpactParams ImpactParams;
		ImpactParams.ActionType = Action;
		ImpactParams.MovementState = AudioMoveComp.GetActiveMovementTag(MOVEMENT_GROUP_NAME);	
		ImpactParams.HandVelo = TraceData.VeloSpeed;

		UPhysicalMaterial PhysMat = nullptr;

		if(Action == EHandTraceAction::Plant
		|| Action == EHandTraceAction::StartSlide)
		{
			PhysMat = TraceData.GroundedPhysMat;
		}
		else
		{
			PhysMat = TraceData.LastPhysMat;
		}

		if (PhysMat.AudioAsset == nullptr)
		{
			Warning(f"We have a physmaterial '{PhysMat.Name}' but it's missing an audio material!");
			return;
		}

		ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);
		switch(Action)
		{
			case(EHandTraceAction::Plant):			
				PerformHandOneshot(TraceData, ImpactParams); break;
			
			case(EHandTraceAction::Release):
				PerformHandOneshot(TraceData, ImpactParams); break;	
			
			case(EHandTraceAction::StartSlide):
			{
				AudioMoveComp.AddHandSliding(TraceData.Hand);
				break;
			}
			case(EHandTraceAction::StopSlide):
			{	
				AudioMoveComp.RemoveHandSliding(TraceData.Hand);
				break;
			}
			default:
				break;
		}		
	}

	private void PerformHandOneshot(FHandTraceData& TraceData, FPlayerHandImpactParams& ImpactParams)
	{
		if(MaterialComp.GetMaterialEvent(ImpactParams.AudioPhysMat.FootstepData.FootstepTag, ImpactParams.MovementState, ImpactParams.ActionType, ImpactParams.MaterialEvent))
		{
			ImpactParams.MakeUpGain = TraceData.Settings.MakeUpGain;
			ImpactParams.Pitch = TraceData.Settings.Pitch;

			float TriggerTimestamp = TraceData.Trace.bGrounded ? TraceData.PlantTriggerTimeStamp : TraceData.ReleaseTriggerTimeStamp;
			if(Time::GetRealTimeSince(TriggerTimestamp) >= TraceData.Settings.TriggerCooldown)
			{
				if(TraceData.Hand == EHandType::Left)
					UMovementAudioEventHandler::Trigger_OnHandTrace_Left(Player, ImpactParams);
				else
					UMovementAudioEventHandler::Trigger_OnHandTrace_Right(Player, ImpactParams);

				if(bDebugActive)
				{
					if(ImpactParams.ActionType == EHandTraceAction::Plant)
						Debug::DrawDebugPoint(TraceData.Hit.Location, 15.0, FLinearColor::Yellow, Duration = 3.0);
				}

				if(TraceData.Trace.bGrounded)
					TraceData.PlantTriggerTimeStamp = Time::GetRealTimeSeconds();
				else
					TraceData.ReleaseTriggerTimeStamp = Time::GetRealTimeSeconds();
			}
			else
			{
				if(bDebugActive)
				{
					if(ImpactParams.ActionType == EHandTraceAction::Plant)
						Debug::DrawDebugPoint(TraceData.Hit.Location, 15.0, FLinearColor::Purple, Duration = 3.0);
				}
			}
		}
	}

	private FVector GetTraceFrameStartPos(const FHandTraceData& InTraceData)
	{	
		return Player.Mesh.GetSocketLocation(InTraceData.Settings.SocketName);		
	}

	private FVector GetTraceFrameEndPos(const FHandTraceData& InTraceData)
	{
		FVector Direction;
		if(InTraceData.Settings.WorldTarget != nullptr)
		{
			Direction = (InTraceData.Settings.WorldTarget.GetWorldLocation() - InTraceData.Start).GetSafeNormal();
		}
		else
		{
			const FRotator TraceRot = Player.Mesh.GetSocketRotation(InTraceData.Settings.SocketName);
			Direction = TraceRot.ForwardVector;
		}

		return InTraceData.Start + (Direction * -InTraceData.ScaledTraceLength);
	}

	private bool ValidateHandFrameVelo(FHandTraceData& InTraceData, const float DeltaTime)
	{	
		FVector CachedHandLocation;
		if(!TrackedHandLocations.Find(InTraceData.Hand, CachedHandLocation))
			return false;

		InTraceData.Velo = InTraceData.Start - CachedHandLocation;	

		if(InTraceData.ContactActor != nullptr)
		{
			InTraceData.ContactActorVelocity = InTraceData.ContactActor.ActorLocation - TrackedHandContactActorLocations[InTraceData.Hand];
		}

		InTraceData.Velo -= InTraceData.ContactActorVelocity;
		InTraceData.VeloSpeed = InTraceData.Velo.Size() / DeltaTime;

		// Has the hand moved enough?
		InTraceData.bValidFrameVelo = InTraceData.Velo.Size() >= InTraceData.Settings.MinRequiredVelo;
		return InTraceData.bValidFrameVelo;		
	}	

	private bool CanStartSliding(const FHandTraceData& TraceData)
	{
		if(!TraceData.Settings.bCanSlide)
			return false;

		if(!TraceData.Settings.bPerHandSliding && AudioMoveComp.IsHandSliding(GetOtherHandData(TraceData).Hand))
			return false;

		auto PlayerVerticalVelo = MoveComp.VerticalVelocity;
		if(PlayerVerticalVelo.Size() < TraceData.Settings.MinRequiredVelo)
			return false;

		if(TraceData.Settings.bLimitSlidingDownwards)
		{				
			// const FVector HandVerticalVelo = TraceData.Velo.ConstrainToDirection(Player.MovementWorldUp);
			// const float VerticalDot = Player.MovementWorldUp.DotProduct(HandVerticalVelo);

			const float VerticalDot = PlayerVerticalVelo.GetSafeNormal().DotProduct(Player.MovementWorldUp.GetSafeNormal());
			if(VerticalDot > 0)
				return false;
		}	

		return Time::GetGameTimeSince(TraceData.Trace.GroundedTimestamp) >= TraceData.Settings.SlidingDelay;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		auto AudioLog = TEMPORAL_LOG(this, Player, "Audio/Hand");

		LogToTemporal(EHandType::Left, AudioLog);
		LogToTemporal(EHandType::Right, AudioLog);
	}

	private void LogToTemporal(const EHandType Hand, FTemporalLog Log) const
	{
		FHandTraceData& TraceData = TraceComp.GetTraceData(Hand);

		const FString LogGroup = Hand == EHandType::Left ? "10#Left" : "20#Right";

		FName MaterialTag = NAME_None;
		if(TraceData.Trace.bGrounded && TraceData.GroundedPhysMat != nullptr)
		{
			auto AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(TraceData.GroundedPhysMat.AudioAsset);
			if(AudioPhysMat != nullptr)
			{
				MaterialTag = AudioPhysMat.FootstepData.FootstepTag;
			}
			else
			{
				MaterialTag = n"Missing AudioPhysMat!";
			}
		}

		if(MaterialComp.CheckMovementOverrideMaterialTag(EFootType::Release, MaterialTag))
		{
			MaterialTag = FName(f"{MaterialTag} (MATERIAL OVERRIDE)");
		}

		Log
		.Value(f"{LogGroup};Tag", AudioMoveComp.GetActiveMovementTag(MOVEMENT_GROUP_NAME))
		.Value(f"{LogGroup};Is Grounded", TraceData.Trace.bGrounded)
		.Value(f"{LogGroup};PhysMat", TraceData.GroundedPhysMat)
		.Value(f"{LogGroup};Material Tag", MaterialTag)
		.Value(f"{LogGroup};Valid Frame Velo", TraceData.bValidFrameVelo)
		.Value(f"{LogGroup};Velocity Speed", TraceData.VeloSpeed)
		.Value(f"{LogGroup};Can Slide", TraceData.Settings.bCanSlide)
		.Value(f"{LogGroup};Limit Slide Downwards", TraceData.Settings.bLimitSlidingDownwards)
		.Value(f"{LogGroup};Is Sliding", TraceData.Trace.bIsSliding)
		.Value(f"{LogGroup};Slide Intensity", Math::GetMappedRangeValueClamped(FVector2D(0.0, MovementAudio::Player::MAX_HAND_SLIDE_VELO_SPEED), FVector2D(0.0, 2.0), TraceData.VeloSpeed));
	}
}