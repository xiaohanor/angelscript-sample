class UAnimNotify_TundraMonkeyFootstep : UAnimNotify_HazeSoundDefTrigger
{
	default SoundDefClass = UGameplay_Character_Creature_Player_Tundra_SnowMonkey_SoundDef;

	UPROPERTY(EditInstanceOnly)
	ETundraMonkeyFootType FootType;

	UPROPERTY(EditInstanceOnly)
	bool bIsPlant = true;

	const float SLOPE_TILT_MAX_ANGLE = 45.0;
	const float LANDING_VELOCITY_NORMALIZE_RANGE = 2850;

	UGameplay_Character_Creature_Player_Tundra_SnowMonkey_SoundDef GetMonkeySoundDef() const property
	{
		return Cast<UGameplay_Character_Creature_Player_Tundra_SnowMonkey_SoundDef>(SoundDef); 
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(FootType == ETundraMonkeyFootType::None)
			return false;

		ATundraPlayerSnowMonkeyActor Monkey = Cast<ATundraPlayerSnowMonkeyActor>(MeshComp.Owner);
		if(Monkey == nullptr || MonkeySoundDef == nullptr)
			return false;

		// See if notify is a basic one that we can handle early
		if(HandleNotify())
			return true;

		UTundraMonkeyFootstepTraceAudioComponent TraceComp = UTundraMonkeyFootstepTraceAudioComponent::Get(Monkey.Player);	
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Monkey.Player);
		FTundraMonkeyFootstepTraceData& TraceData = TraceComp.GetTraceData(FootType);	

		if(!CanPerformFootstep(TraceData))
			return false;

		// Reset performed-flag
		TraceData.Trace.bPerformed = false;
		TraceData.Start = TraceComp.GetTraceFrameStartPos(TraceData);

		const float TraceLength = TraceComp.GetScaledTraceLength(TraceData);

		TraceData.End = TraceComp.GetTraceFrameEndPos(TraceData, TraceLength);

		if(!TraceComp.PerformFootTrace_Sphere(TraceData, TraceData.Settings.SphereTraceRadius, bDebug = false))
			return false;

		if(bIsPlant)		
			TraceData.PlantTriggerTimeStamp = Time::GetRealTimeSeconds();		
		else		
			TraceData.ReleaseTriggerTimeStamp = Time::GetRealTimeSeconds();	

		// Execute footstep!

		UPhysicalMaterial PhysMat = TraceData.PhysMat;
		UPhysicalMaterialAudioAsset AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);

		if(IsFootstep())
		{
			FTundraMonkeyFootstepParams FootstepParams;
			FootstepParams.Foot = FootType;
			FootstepParams.Pitch = TraceData.Settings.Pitch;	
			FootstepParams.FootstepType = GetFootstepType();	
			FootstepParams.SurfaceType = AudioPhysMat.HardnessType;	
				
			MonkeySoundDef.SurfaceAddEvents.Find(AudioPhysMat.FootstepData.FootstepTag, FootstepParams.SurfaceAddEvent);
			
			// Slope Tilt
			const FVector ForwardVeloDir = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			const float Sign = Math::Sign(MoveComp.Velocity.Z - ForwardVeloDir.Z);
			float TiltDeg = Math::DotToDegrees(MoveComp.Velocity.GetSafeNormal().DotProduct(ForwardVeloDir));

			TiltDeg *= Sign;

			FootstepParams.SlopeTilt = Math::GetMappedRangeValueClamped(FVector2D(-SLOPE_TILT_MAX_ANGLE, SLOPE_TILT_MAX_ANGLE), FVector2D(-1.0, 1.0), TiltDeg);					

			if(bIsPlant)
			{			
				UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnFootstepTrace_Plant(Monkey, FootstepParams);
			}		
			else
			{
				UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnFootstepTrace_Release(Monkey, FootstepParams);
			}
		}
		else if(IsJumpLand() || IsRoll())
		{
			FTundraMonkeyJumpLandParams JumpLandParams;
			const float VerticalVeloSpeed = MonkeySoundDef.GetFallingSpeed();
			const float NormalizedVerticalVeloSpeed = Math::GetMappedRangeValueClamped(FVector2D(0, LANDING_VELOCITY_NORMALIZE_RANGE), FVector2D(0, 1), VerticalVeloSpeed);

			JumpLandParams.Intensity = NormalizedVerticalVeloSpeed;

			FTundraMonkeyFootstepDatas FootstepDatas;
			MonkeySoundDef.FootstepEvents.Find(AudioPhysMat.HardnessType, FootstepDatas);

			switch(FootType)
			{
				case(ETundraMonkeyFootType::Jump):
				{
					JumpLandParams.SurfaceEvent = FootstepDatas.JumpEvent;
					UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnFootstepTrace_Jump(Monkey, JumpLandParams);
					break;
				}
				case(ETundraMonkeyFootType::Land):
				{
					JumpLandParams.SurfaceEvent = FootstepDatas.LandEvent;
					UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnFootstepTrace_Land(Monkey, JumpLandParams);
					break;
				}
				case(ETundraMonkeyFootType::Roll):
				{
					JumpLandParams.SurfaceEvent = FootstepDatas.RollEvent;
					UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnFootstepTrace_Roll(Monkey, JumpLandParams);
					break;
				}
				default: break;
			}		
		}

		return true;
	}

	private bool HandleNotify() const
	{
		if(IsFootstep() || IsJumpLand() || IsRoll())
		 return false;
		
		switch(FootType)
		{
			case(ETundraMonkeyFootType::GroundSlamUp): MonkeySoundDef.OnGroundSlamFistsUp(); return true;
			case(ETundraMonkeyFootType::GroundSlamDown): MonkeySoundDef.OnGroundSlamFistsDown(); return true;
			case(ETundraMonkeyFootType::HangClimbGrab): MonkeySoundDef.OnHangClimb_Grab(); return true;
			case(ETundraMonkeyFootType::PoleClimbGrab): MonkeySoundDef.OnPoleClimb_Grab(); return true;
			case(ETundraMonkeyFootType::PoleClimbEnter): MonkeySoundDef.OnPoleClimbEnter(); return true;
			default: break;
		}

		return false;
	}

	private bool CanPerformFootstep(const FTundraMonkeyFootstepTraceData& TraceData) const
	{
		if(bIsPlant)
			return Time::GetRealTimeSince(TraceData.PlantTriggerTimeStamp) >= TraceData.Settings.TriggerCooldown;		

		return Time::GetRealTimeSince(TraceData.ReleaseTriggerTimeStamp) >= TraceData.Settings.TriggerCooldown;		
 
	}

	private ETundraMonkeyFootstepType GetFootstepType() const
	{
		if(!bIsPlant)
			return ETundraMonkeyFootstepType::Release;
		
		switch(FootType)
		{
			case(ETundraMonkeyFootType::LeftFoot): return ETundraMonkeyFootstepType::Foot;
			case(ETundraMonkeyFootType::RightFoot): return ETundraMonkeyFootstepType::Foot;
			case(ETundraMonkeyFootType::LeftHand): return ETundraMonkeyFootstepType::Hand;
			case(ETundraMonkeyFootType::RightHand): return ETundraMonkeyFootstepType::Hand;
			default: break;
		}

		return ETundraMonkeyFootstepType::Foot;
	}

	private bool IsFootstep() const
	{
		return FootType == ETundraMonkeyFootType::LeftFoot 
		||	 FootType == ETundraMonkeyFootType::RightFoot
		||	FootType == ETundraMonkeyFootType::LeftHand
		|| FootType == ETundraMonkeyFootType::RightHand;
	}

	private bool IsJumpLand() const
	{
		return FootType == ETundraMonkeyFootType::Jump 
		||	 FootType == ETundraMonkeyFootType::Land;
	}

	private bool IsRoll() const
	{
		return FootType == ETundraMonkeyFootType::Roll;
	}
}