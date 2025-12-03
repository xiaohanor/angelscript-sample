class UAnimNotify_FantasyOtterFootstep : UAnimNotify_HazeSoundDefTrigger
{
	default SoundDefClass = UGameplay_Character_Creature_Player_Tundra_FantasyOtter_SoundDef;

	UGameplay_Character_Creature_Player_Tundra_FantasyOtter_SoundDef GetOtterSoundDef() const property
	{
		return Cast<UGameplay_Character_Creature_Player_Tundra_FantasyOtter_SoundDef>(SoundDef);
	}

	UPROPERTY(EditInstanceOnly)
	EFantasyOtterFootType FootType = EFantasyOtterFootType::LeftFoot;

	UPROPERTY(EditInstanceOnly)
	bool bIsPlant = true;

	const float SLOPE_TILT_MAX_ANGLE = 45.0;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(FootType == EFantasyOtterFootType::None)
			return false;

		ATundraPlayerOtterActor Otter = Cast<ATundraPlayerOtterActor>(MeshComp.GetOwner());

		if(Otter == nullptr || OtterSoundDef == nullptr)
			return false;

		UFantasyOtterFootstepTraceAudioComponent TraceComp = UFantasyOtterFootstepTraceAudioComponent::Get(Otter.Player);
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Otter.Player);
		FFantasyOtterFootstepTraceData& TraceData = TraceComp.GetTraceData(FootType);	

		if(!CanPerformFootstep(TraceData))
			return false;

		// Reset performed-flag
		TraceData.Trace.bPerformed = false;
		TraceData.Start = TraceComp.GetTraceFrameStartPos(TraceData);

		const float TraceLength = TraceComp.GetScaledTraceLength(TraceData);

		TraceData.End = TraceComp.GetTraceFrameEndPos(TraceData, TraceLength);

		UPhysicalMaterial PhysMat = nullptr;
		if(!TraceComp.PerformFootTrace_Sphere(TraceData, TraceData.Settings.SphereTraceRadius))
			return false;

		if(bIsPlant)		
			TraceData.PlantTriggerTimeStamp = Time::GetRealTimeSeconds();		
		else		
			TraceData.ReleaseTriggerTimeStamp = Time::GetRealTimeSeconds();

		PhysMat = TraceData.PhysMat;
		if(PhysMat == nullptr)
			return false;	

		UPhysicalMaterialAudioAsset AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);

		FTundraPlayerOtterFootstepParams FootstepParams;

		FootstepParams.Pitch = TraceData.Settings.Pitch;	

		const FVector ForwardVeloDir = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		const float Sign = Math::Sign(MoveComp.Velocity.Z - ForwardVeloDir.Z);
		float TiltDeg = Math::DotToDegrees(MoveComp.Velocity.GetSafeNormal().DotProduct(ForwardVeloDir));

		TiltDeg *= Sign;

		FootstepParams.SlopeTilt = Math::GetMappedRangeValueClamped(FVector2D(-SLOPE_TILT_MAX_ANGLE, SLOPE_TILT_MAX_ANGLE), FVector2D(-1.0, 1.0), TiltDeg);

		
		FFantasyOtterFootstepSurfaceEvents SurfaceEvents;
		OtterSoundDef.SurfaceEvents.Find(AudioPhysMat.HardnessType, SurfaceEvents);

		OtterSoundDef.AddEvents.Find(AudioPhysMat.FootstepData.FootstepTag, FootstepParams.SurfaceAddEvent);

		if(bIsPlant)
		{			
			FootstepParams.SurfaceEvent = SurfaceEvents.Plant;

			// This could be implemented so much nicer in the future, but for now only use add event if one was found
			if(FootstepParams.SurfaceAddEvent != nullptr)
				FootstepParams.SurfaceEvent = FootstepParams.SurfaceAddEvent;

			UTundraPlayerOtterEffectHandler::Trigger_OnFootstepTrace_Plant(Otter, FootstepParams);
		}		
		// else
		// {
		// 	FootstepParams.SurfaceEvent = SurfaceEvents.Release;
		// 	UTundraPlayerOtterEffectHandler::Trigger_OnFootstepTrace_Release(Otter, FootstepParams);
		// }


		return true;
	}

	private bool CanPerformFootstep(const FFantasyOtterFootstepTraceData& TraceData) const
	{
		if(bIsPlant)
			return Time::GetRealTimeSince(TraceData.PlantTriggerTimeStamp) >= TraceData.Settings.TriggerCooldown;		

		return Time::GetRealTimeSince(TraceData.ReleaseTriggerTimeStamp) >= TraceData.Settings.TriggerCooldown;		
 
	}	
}


