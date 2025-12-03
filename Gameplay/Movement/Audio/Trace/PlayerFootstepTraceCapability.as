class UPlayerFootstepTraceTemporalLogExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Player Footstep Trace Temporal Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
	#if EDITOR
		auto Capability = Cast<UPlayerFootstepTraceCapability>(Report.AssociatedObject);
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
			auto Capability = Cast<UPlayerFootstepTraceCapability>(Report.AssociatedObject);
			if(Capability != nullptr)
			{
				Capability.bDebugActive = !Capability.bDebugActive;
			}
		}		
	}
}

class UPlayerFootstepTraceCapability : UHazePlayerCapability
{	
	default TickGroup = EHazeTickGroup::Audio;
    default DebugCategory = n"Audio";

	UPROPERTY(EditDefaultsOnly)
	UAudioPlayerFootTraceSettings DefaultPlayerFootTraceSettings;

	UPlayerFootstepTraceComponent TraceComp;
	const EFootstepTraceType TraceType = EFootstepTraceType::Sphere;

	FName MovementTag = NAME_None;

	const float SPHERE_TRACE_RADIUS = 5.0;
	const float SLOPE_TILT_MAX_ANGLE = 45.0;
	const float FORWARD_VELO_STRAFE_DOT_THRESHOLD = 0.25;
	const float ADD_SCUFF_HIGH_INT_THRESHOLD = 350.0;
	const float DOWN_SLOPE_FORCE_SCUFF_THRESHOLD = -0.5;
	
	FFootstepTrace LeftFootTrace;
	FFootstepTrace RightFootTrace;

	bool bDebugActive = false;

	TMap<EFootType, FVector> TrackedFootLocations;
	UPlayerMovementAudioComponent PlayerMoveAudioComp;
	UPlayerAudioMaterialComponent MaterialComp;
	UHazeMovementComponent MoveComp;
	UPlayerStrafeComponent StrafeComp;

	FVector CachedPlayerLocation;
	const FName MOVEMENT_GROUP_NAME = n"Player_Foot";

	const FName SCUFF_LOW_INT_TAG = n"Scuff_LowInt";
	const FName SCUFF_HIGH_INT_TAG = n"Scuff_HighInt";

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MovementAudio::Player::CanPerformFootsteps(PlayerMoveAudioComp))
			return false;

		if(PlayerMoveAudioComp.IsDefaultMovementBlocked())
			return false;

		// if(MoveComp.IsInAir())
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MovementAudio::Player::CanPerformFootsteps(PlayerMoveAudioComp))
			return true;

		if(PlayerMoveAudioComp.IsDefaultMovementBlocked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerMoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
		TraceComp = UPlayerFootstepTraceComponent::Get(Player);
		MaterialComp = UPlayerAudioMaterialComponent::Get(Player);
		StrafeComp = UPlayerStrafeComponent::Get(Player);

		FPlayerFootstepTraceData& LeftFootTraceData = TraceComp.GetTraceData(EFootType::Left);	
		LeftFootTraceData.Foot = EFootType::Left;
		LeftFootTraceData.Trace = LeftFootTrace;

		FPlayerFootstepTraceData& RightFootTraceData = TraceComp.GetTraceData(EFootType::Right);
		RightFootTraceData.Foot = EFootType::Right;
		RightFootTraceData.Trace = RightFootTrace;

		#if EDITOR
		TemporalLog::RegisterExtender(this, Player, "Audio/Foot", n"PlayerFootstepTraceTemporalLogExtender", );
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovementTag = NAME_None;

		FPlayerFootstepTraceData& LeftFootTraceData = TraceComp.GetTraceData(EFootType::Left);
		InitializeFootData(LeftFootTraceData);

		FPlayerFootstepTraceData& RightFootTraceData = TraceComp.GetTraceData(EFootType::Right);
		InitializeFootData(RightFootTraceData);	

		if(DefaultPlayerFootTraceSettings !=  nullptr)
			Player.ApplySettings(DefaultPlayerFootTraceSettings, this);
	}

	FVector GetTraceFrameStartPos(const FPlayerFootstepTraceData& InTraceData)
	{
		return Player.Mesh.GetSocketLocation(InTraceData.Settings.SocketName);
	}

	FVector GetTraceFrameEndPos(const FPlayerFootstepTraceData& InTraceData, const float InTraceLength)
	{	
		FVector Direction;
		if(InTraceData.Settings.WorldTarget != nullptr)
		{
			Direction = (InTraceData.Settings.WorldTarget.GetWorldLocation() - InTraceData.Start).GetSafeNormal();
		}
		else
		{
			const FRotator TraceRot = Player.Mesh.GetSocketRotation(InTraceData.Settings.SocketName) + InTraceData.Settings.TraceRotationOffset;
			Direction = TraceRot.ForwardVector;
		}

		return InTraceData.Start - Direction * -InTraceLength;
	}

	float GetScaledTraceLength(FPlayerFootstepTraceData& InFootstepTraceData) const
	{
		const float NormalizedSpeed = Math::Saturate(MoveComp.GetVelocity().Size() / InFootstepTraceData.Settings.MaxVelo);
		const float Alpha = Math::Pow(NormalizedSpeed, 2.0);

		// If we're running downhill we should make the trace a bit longer than normal to avoid erronous double-triggering
		const float SlopeTilt = GetSlopeTiltAngle();
		float SlopeTiltLengthMultiplier = 1.0;
		if (SlopeTilt < -KINDA_SMALL_NUMBER)
			SlopeTiltLengthMultiplier = Math::Lerp(1.0, 1.5, (Math::Abs(SlopeTilt)/ 1.0));

		const float ScaledLength = (Math::Lerp(InFootstepTraceData.Settings.MinLength, InFootstepTraceData.Settings.MaxLength, Alpha)) * SlopeTiltLengthMultiplier;
		return ScaledLength;
	}

	float GetSlopeTiltAngle() const
	{
		// If we're not grounded slope tilt doesn't matter
		if(!MoveComp.IsOnAnyGround())
			return 0.0;
		
		const FVector ForwardVeloDir = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		const float Sign = Math::Sign(MoveComp.Velocity.Z - ForwardVeloDir.Z);
		float TiltDeg = Math::DotToDegrees(MoveComp.Velocity.GetSafeNormal().DotProduct(ForwardVeloDir));

		TiltDeg *= Sign;

		return Math::GetMappedRangeValueClamped(FVector2D(-SLOPE_TILT_MAX_ANGLE, SLOPE_TILT_MAX_ANGLE), FVector2D(-1.0, 1.0), TiltDeg);
	}

	bool ValidateFootFrameVelo(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		FVector CachedLocation;
		if(!TrackedFootLocations.Find(InFootstepTraceData.Foot, CachedLocation))
			return false;

		const FVector Delta = (InFootstepTraceData.Start - CachedLocation);
		const FVector PlayerVelo = Player.GetActorLocation() - CachedPlayerLocation;
		InFootstepTraceData.Velo = Delta - PlayerVelo;

		// Has the foot moved enough?		
		if(Delta.Size() < InFootstepTraceData.Settings.MinRequiredVelo)
			return false;	

		// Has the foot to much upwards velocity to invalidate a new footstep?
		if(!InFootstepTraceData.Settings.bAllowStepUp)
		{
			float WorldUpDot = TraceComp.MoveComp.WorldUp.GetSafeNormal().DotProduct(Delta.GetSafeNormal());
			if(WorldUpDot > 0.5)		
			{
				// If we've already played a release we invalidate the trace for this frame here
				if(!InFootstepTraceData.Trace.bGrounded)
					InFootstepTraceData.Trace.bPerformed = true;	
			}	
		}

		return true;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FPlayerFootstepTraceData& LeftFootTraceData = TraceComp.GetTraceData(EFootType::Left);
		FPlayerFootstepTraceData& RightFootTraceData = TraceComp.GetTraceData(EFootType::Right);

		MovementTag = PlayerMoveAudioComp.GetActiveMovementTag(MOVEMENT_GROUP_NAME);
		if(MovementTag != NAME_None)
		{
			QueryFoot(LeftFootTraceData);
			QueryFoot(RightFootTraceData);
		}

		TrackedFootLocations.FindOrAdd(EFootType::Left) = LeftFootTraceData.Start;
		TrackedFootLocations.FindOrAdd(EFootType::Right) = RightFootTraceData.Start;

		CachedPlayerLocation = Player.GetActorLocation();
	}

	void QueryFoot(FPlayerFootstepTraceData& TraceData)
	{
		if(EvaluateTrace(TraceData))	
		{	
			if(!CanPerformFootstep(TraceData))
				return;

			const bool bIsPlant = TraceData.Trace.bGrounded;
			FPlayerFootstepParams FootstepParams;
			FootstepParams.MovementState = MovementTag;

			UPhysicalMaterial PhysMat = nullptr;
			if(bIsPlant)
			{
				FHazeTraceSettings TraceSettings = TraceComp.InitTraceSettings();
				PhysMat = AudioTrace::GetPhysMaterialFromHit(TraceData.Hit, TraceSettings);	
				TraceData.LastPhysMat = PhysMat;
			}
			else
			{
				PhysMat = TraceData.LastPhysMat;
				if(PhysMat == nullptr)
					return;
			}

			if (TraceComp.FoliageMaterialOverride == nullptr && PhysMat.AudioAsset == nullptr)
			{
				Warning(f"We have a physmaterial '{PhysMat.Name}' but it's missing an audio material!");
				return;
			}

			FootstepParams.AudioPhysMat = TraceComp.FoliageMaterialOverride != nullptr ? TraceComp.FoliageMaterialOverride : Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);
			FootstepParams.FootStepType = TraceData.Hit.bBlockingHit ? TraceData.Foot : EFootType::Release;
			FootstepParams.MakeUpGain = TraceData.Settings.MakeUpGain;
			FootstepParams.Pitch = TraceData.Settings.Pitch;
			FootstepParams.SlopeTilt = GetSlopeTiltAngle();
			FootstepParams.PhysicalSurfaceType = PhysMat.SurfaceType;
			FootstepParams.ImpactPoint = TraceData.Hit.ImpactPoint;
			FootstepParams.ImpactNormal = TraceData.Hit.ImpactNormal;

			bool bIsBothFeet = false;
			EFootType FootType = bIsPlant ? TraceData.Foot : EFootType::Release;

			if(MaterialComp.GetMaterialEvent(FootstepParams.AudioPhysMat.FootstepData.FootstepTag, FootstepParams.MovementState, TraceData.Foot, FootType, FootstepParams.MaterialEvent, bIsBothFeet))
			{	
				// Check if we want to add an additional scuff event to play on top
				if(!IsInScuffingTag() && TraceData.Trace.bGrounded)
				{
					// If we're running uphill/downhill or strafing
					if(Math::Abs(FootstepParams.SlopeTilt) > 0.0 || IsStrafing())
					{
						const FName ScuffIntensityTag = GetScuffAddIntensityTag();
						MaterialComp.GetMaterialEvent(FootstepParams.AudioPhysMat.FootstepData.FootstepTag, ScuffIntensityTag, TraceData.Foot, FootType, FootstepParams.AddScuffEvent);					

						FootstepParams.AddScuffMakeUpGain = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(-14, 0.0), FootstepParams.SlopeTilt);
					}		

					// Increase Gain of plants if running downhill	
					if(bIsPlant && FootstepParams.SlopeTilt < 0.0)
					{
						const float MaxDownhillAngleAddativeMakeUpGainDB = 4.0;
						const float AddativeDownhillMakeUpGain = Math::GetMappedRangeValueClamped(FVector2D(0.0, -1.0), FVector2D(0.0, MaxDownhillAngleAddativeMakeUpGainDB), FootstepParams.SlopeTilt);
						FootstepParams.MakeUpGain += AddativeDownhillMakeUpGain;
					}
				}

				switch(TraceData.Foot)
				{
					case(EFootType::Left):  UMovementAudioEventHandler::Trigger_OnFootstepTrace_Left(Player, FootstepParams); break;
					case(EFootType::Right): UMovementAudioEventHandler::Trigger_OnFootstepTrace_Right(Player, FootstepParams); break;
					default: break;	
				}

				QueryCooldowns(TraceData, bIsBothFeet);
			}		
		}
	}

	bool EvaluateTrace(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		// Reset performed-flag
		InFootstepTraceData.Trace.bPerformed = false;

		#if EDITOR
			InFootstepTraceData.bInvalidated = false;
		#endif

		// Get trace bounds from foot
		InFootstepTraceData.Start = GetTraceFrameStartPos(InFootstepTraceData);

		// If foot hasn't moved, or moved in opposite direction of ground, bail
		const bool bValidFrameVelo = ValidateFootFrameVelo(InFootstepTraceData);

		#if EDITOR
			InFootstepTraceData.bValidFrameVelo = bValidFrameVelo;
		#endif

		if(!bValidFrameVelo)
			return false;
		
		// Get Foot Trace Length	
		const float TraceLength = GetScaledTraceLength(InFootstepTraceData);

		InFootstepTraceData.End = GetTraceFrameEndPos(InFootstepTraceData, TraceLength);
		
		if (PlayerMoveAudioComp.OnFootTrace.IsBound())
		{
			PlayerMoveAudioComp.OnFootTrace.Broadcast(InFootstepTraceData);
		}
		
		if(TraceType == EFootstepTraceType::Box)
		{
			InFootstepTraceData.ScaledBoxExtends = Player.Mesh.GetSocketTransform(InFootstepTraceData.Settings.SocketName).Scale3D;

			// Apply box trace shape scale offset if set
			if(InFootstepTraceData.FootTraceTransformOffset.Scale3D != FVector::OneVector)
				InFootstepTraceData.ScaledBoxExtends += InFootstepTraceData.FootTraceTransformOffset.Scale3D;

			FQuat Orientation = Player.Mesh.GetSocketQuaternion(InFootstepTraceData.Settings.SocketName);
			if(TraceComp.PerformTrace_Box(InFootstepTraceData, Orientation, bDebug = bDebugActive))	
			{			
				return true;			
			}
		}
		else if(TraceType == EFootstepTraceType::Sphere)
		{
			if(TraceComp.PerformFootTrace_Sphere(InFootstepTraceData, InFootstepTraceData.Settings.SphereTraceRadius, bDebug = bDebugActive))
			{
				return true;
			}
		}
		else
		{
			// First perform trace based on last known plane normal
			if(TraceComp.PerformTrace_Simple(InFootstepTraceData))	
			{
				if(IsDebugActive())
					PrintToScreenScaled(""+ InFootstepTraceData.Foot +  " - Primary Line Trace", 0.5, Scale = 2.0);

				return true;
			}
		}			

		return false;
	}	

	private FName GetScuffAddIntensityTag()
	{		
		if(MoveComp.Velocity.Size() < ADD_SCUFF_HIGH_INT_THRESHOLD)
			return SCUFF_LOW_INT_TAG;

		return SCUFF_HIGH_INT_TAG;
	}

	private bool IsInScuffingTag()
	{
		return
		MovementTag == SCUFF_LOW_INT_TAG ||
		MovementTag == SCUFF_HIGH_INT_TAG;
	}

	private bool IsStrafing()
	{
		if(StrafeComp.IsStrafeEnabled())
			return true;

		if(MoveComp.Velocity.IsNearlyZero())
			return false;

		const float StrafeDot = Player.ActorForwardVector.DotProduct(MoveComp.Velocity.GetSafeNormal());
		return Math::Abs(StrafeDot) < FORWARD_VELO_STRAFE_DOT_THRESHOLD;
	}

	private bool CanPerformFootstep(FPlayerFootstepTraceData& TraceData) const
	{
		const float TriggerTimeStamp = TraceData.Trace.bGrounded ? TraceData.PlantTriggerTimeStamp : TraceData.ReleaseTriggerTimeStamp;
		const bool bCooldownReady = Time::GetRealTimeSince(TriggerTimeStamp) >= TraceData.Settings.TriggerCooldown;	

		#if EDITOR
			TraceData.bCooldownReady = bCooldownReady;
		#endif

		return bCooldownReady;		
	}

	protected void QueryCooldowns(FPlayerFootstepTraceData& TraceData, const bool bIsBothFeet)
	{
		if(TraceData.Trace.bGrounded)
		{
			TraceData.PlantTriggerTimeStamp = Time::GetRealTimeSeconds();
			if(bIsBothFeet || TraceData.Settings.bForceSharedCooldowns)
			{
				GetOtherFoot(TraceData).PlantTriggerTimeStamp = TraceData.PlantTriggerTimeStamp;
			}
		}
		else
		{
			TraceData.ReleaseTriggerTimeStamp = Time::GetRealTimeSeconds();
			if(bIsBothFeet || TraceData.Settings.bForceSharedCooldowns)
			{
				GetOtherFoot(TraceData).ReleaseTriggerTimeStamp = TraceData.ReleaseTriggerTimeStamp;
			}
		}
	}

	private FPlayerFootstepTraceData& GetOtherFoot(const FPlayerFootstepTraceData& InTraceData)
	{
		if(InTraceData.Foot == EFootType::Left)
			return TraceComp.GetTraceData(EFootType::Right);
		
		return TraceComp.GetTraceData(EFootType::Left);
	}

	void InitializeFootData(FPlayerFootstepTraceData& InFootData)
	{
		InFootData.PlantTriggerTimeStamp = InFootData.Settings.TriggerCooldown;
		InFootData.ReleaseTriggerTimeStamp = InFootData.Settings.TriggerCooldown;

		InFootData.Trace.bGrounded = false;
		InFootData.Trace.bPerformed = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		FName PlayerName = Player.IsMio() ? n"Mio" : n"Zoe";
		auto AudioLog = TEMPORAL_LOG(this, Player, "Audio/Foot");	
		Log(EFootType::Left, AudioLog);
		Log(EFootType::Right, AudioLog);		
	}

	private void Log(const EFootType Foot, FTemporalLog TemporalLog)
	{
		FPlayerFootstepTraceData& TraceData = TraceComp.GetTraceData(Foot);

		FName MaterialTag = NAME_None;
		if(TraceData.Trace.bGrounded && TraceData.GroundedPhysMat != nullptr)
		{
			auto AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(TraceData.GroundedPhysMat.AudioAsset);
			if(AudioPhysMat != nullptr)
			{
				if (TraceComp.FoliageMaterialOverride != nullptr)
				{
					MaterialTag = FName(f"{AudioPhysMat.FootstepData.FootstepTag} (FOLIAGE OVERRIDE)");
				}
				else
					MaterialTag = AudioPhysMat.FootstepData.FootstepTag;
			}
			else
			{
				MaterialTag = n"Missing AudioPhysMat!";
			}
		}

		if(MaterialComp.CheckMovementOverrideMaterialTag(Foot, MaterialTag))
		{
			MaterialTag = FName(f"{MaterialTag} (MATERIAL OVERRIDE)");
		}

		const FString Category = Foot == EFootType::Left ? "10#Left" : "10#Right";
		const float  TraceLength = GetScaledTraceLength(TraceData);

		TemporalLog		
			.Value(f"{Category};Foot Tag", PlayerMoveAudioComp.GetActiveMovementTag(MOVEMENT_GROUP_NAME))
			.Value(f"{Category};Trace length", TraceLength)
			.Value(f"{Category};Is Grounded", TraceData.Trace.bGrounded)
			.Value(f"{Category};PhysMat", TraceData.Trace.bGrounded ? TraceData.GroundedPhysMat.GetName() : n"None")
			//.Value(f"{Category};Settings", TraceData.Settings)		
			.Value(f"{Category};HitComponent", TraceData.Hit.Component)
			.Value(f"{Category};Material Tag", MaterialTag)
			.Value(f"{Category};Player Speed", MoveComp.Velocity.Size())
			.Value(f"{Category};Slope Tilt", GetSlopeTiltAngle())
			.Value(f"{Category};Time since Plant", Time::GetRealTimeSince(TraceData.PlantTriggerTimeStamp))
			.Value(f"{Category};Time since Release", Time::GetRealTimeSince(TraceData.ReleaseTriggerTimeStamp));

		// #if EDITOR
		// 	.Value(f"{Category};Invalidated", TraceData.bInvalidated)
		// 	.Value(f"{Category};Valid Frame Velo", TraceData.bValidFrameVelo)		
		// 	.Value(f"{Category};Cooldown Ready", TraceData.bCooldownReady);
		// #endif		

		if(bDebugActive && TraceData.Settings.TraceRotationOffset != FRotator::ZeroRotator)
		{
			Debug::DrawDebugArrow(TraceData.Start, TraceData.End + ((TraceData.End - TraceData.Start).GetSafeNormal() * 10), bDrawInForeground = true);
		}	
	}
}
