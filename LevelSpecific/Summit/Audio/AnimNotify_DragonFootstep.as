class UAnimNotify_DragonFootstep : UAnimNotify_HazeSoundDefTrigger
{
	default SoundDefClass = UGameplay_Vehicle_Player_Dragon_Teen_SoundDef;
	
	// this will be set to false if VFX needs to place out another animNotify in addition to the ones audio has placed out
	UPROPERTY(EditInstanceOnly)
	bool bPlaySound = true;

	UPROPERTY(EditInstanceOnly)
	bool bIsPlant = true;

	UPROPERTY(EditInstanceOnly)
	EDragonFootType FootType;

	const float SLOPE_TILT_MAX_ANGLE = 25.0;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
	const FAnimNotifyEventReference& InOutReference) const
	{
		if(FootType == EDragonFootType::None)
			return false;

		UGameplay_Vehicle_Player_Dragon_Teen_SoundDef TeenSoundDef = nullptr;
		if(bPlaySound)
		{
			TeenSoundDef = Cast<UGameplay_Vehicle_Player_Dragon_Teen_SoundDef>(SoundDef);
			if(TeenSoundDef == nullptr)
			{
				return false;
			}
		}

		ATeenDragon Dragon = Cast<ATeenDragon>(MeshComp.GetOwner());

		if(Dragon == nullptr)
			return false;

		AHazePlayerCharacter PlayerOwner = Dragon.IsAcidDragon() ? Game::Mio : Game::Zoe;		
		UDragonFootstepTraceComponent TraceComp = UDragonFootstepTraceComponent::Get(PlayerOwner);	
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(PlayerOwner);

		FDragonFootstepTraceData& TraceData = TraceComp.GetTraceData(FootType);
		TraceData.DragonMesh = MeshComp;

		if(!CanPerformFootstep(TraceData))
			return false;

		// Reset performed-flag
		TraceData.Trace.bPerformed = false;
		TraceData.Start = TraceComp.GetTraceFrameStartPos(TraceData);

		const float TraceLength = TraceComp.GetScaledTraceLength(TraceData);

		TraceData.End = TraceComp.GetTraceFrameEndPos(TraceData, TraceLength);

		FDragonFootstepParams FootParams;
		FootParams.MakeUpGain = TraceData.Settings.MakeUpGain;
		FootParams.Pitch = TraceData.Settings.Pitch;
		EDragonFootType FootstepType = FootType;	

		const FVector ForwardVeloDir = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		const float Sign = Math::Sign(MoveComp.Velocity.Z - ForwardVeloDir.Z);
		float TiltDeg = Math::DotToDegrees(MoveComp.Velocity.GetSafeNormal().DotProduct(ForwardVeloDir));

		TiltDeg *= Sign;

		FootParams.SlopeTilt = Math::GetMappedRangeValueClamped(FVector2D(-SLOPE_TILT_MAX_ANGLE, SLOPE_TILT_MAX_ANGLE), FVector2D(-1.0, 1.0), TiltDeg);

		UPhysicalMaterial PhysMat = nullptr;
		if(!TraceComp.PerformFootTrace_Sphere(TraceData, TraceData.Settings.SphereTraceRadius))
			return false;		

		if(bIsPlant)		
			TraceData.PlantTriggerTimeStamp = Time::GetRealTimeSeconds();		
		else		
			TraceData.ReleaseTriggerTimeStamp = Time::GetRealTimeSeconds();

		PhysMat = TraceData.PhysMat;
		FootParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);		

		FootParams.FootStepType = FootstepType;		

		if(bPlaySound)
		{
			TeenSoundDef.OnFootstepPlant_Setup(FootParams);
			if(bIsPlant)
			{
				switch(FootType)
				{
					case(EDragonFootType::FrontLeft) : TeenSoundDef.OnFootstepPlant_FrontLeft(FootParams); break;
					case(EDragonFootType::FrontRight) : TeenSoundDef.OnFootstepPlant_FrontRight(FootParams); break;
					case(EDragonFootType::BackLeft) : TeenSoundDef.OnFootstepPlant_BackLeft(FootParams); break;
					case(EDragonFootType::BackRight) : TeenSoundDef.OnFootstepPlant_BackRight(FootParams); break;
					case(EDragonFootType::LandFront): TeenSoundDef.OnFootstepLand(FootParams); break;
					case(EDragonFootType::LandBack): TeenSoundDef.OnFootstepLand(FootParams); break;
					default: break;
				}	
			}	
			else
			{

				TeenSoundDef.OnFootstepRelease(FootParams);
			}
		}

		FDragonStepData DragonStepData;
        DragonStepData.DragonMesh = TraceData.DragonMesh;
        DragonStepData.bIsPlant = bIsPlant;
        DragonStepData.Hit = TraceData.Hit;
        DragonStepData.PhysMat = TraceData.PhysMat;
        UMovementVFXEventHandler::Trigger_OnDragonStep(PlayerOwner, DragonStepData);
	
		TraceComp.TrackedFootLocations.FindOrAdd(TraceData.Foot, TraceData.Start);	
		TraceComp.CachedDragonLocation = PlayerOwner.GetActorLocation();
		return true;
	}


	private bool CanPerformFootstep(FDragonFootstepTraceData& TraceData) const
	{
		if(bIsPlant)
			return Time::GetRealTimeSince(TraceData.PlantTriggerTimeStamp) >= TraceData.Settings.TriggerCooldown;		

		return Time::GetRealTimeSince(TraceData.ReleaseTriggerTimeStamp) >= TraceData.Settings.TriggerCooldown;		
 
	}
}