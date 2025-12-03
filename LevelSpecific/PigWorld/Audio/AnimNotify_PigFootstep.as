struct FPigFootstepParams
{
	UPROPERTY(BlueprintReadOnly)
	EPigFootType FootType = EPigFootType::None;
	UPROPERTY(BlueprintReadOnly)
	UPhysicalMaterialAudioAsset AudioPhysMat = nullptr;
	UPROPERTY(BlueprintReadOnly)
	float SlopeTilt = 0.0;
}

struct FPigJumpLandParams
{
	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEvent SurfaceEvent = nullptr;

	UPROPERTY(BlueprintReadOnly)
	float Intensity = 0.0;
}

class UAnimNotify_PigFootstep : UAnimNotify_HazeSoundDefTrigger
{
		default SoundDefClass = UGameplay_Character_Creature_Player_Pig_SoundDef;

		const float TRACE_LENGTH = 25;	
		const float SLOPE_TILT_MAX_ANGLE = 45.0;
		const float LANDING_VELOCITY_NORMALIZE_RANGE = 300;

		UGameplay_Character_Creature_Player_Pig_SoundDef GetPigSoundDef() const property
		{
			return Cast<UGameplay_Character_Creature_Player_Pig_SoundDef>(SoundDef);
		}

		UPROPERTY(EditInstanceOnly)
		EPigFootType FootType = EPigFootType::None;

		UFUNCTION(BlueprintOverride)
		bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
					FAnimNotifyEventReference EventReference) const
		{
			auto Player = Cast<AHazePlayerCharacter>(MeshComp.GetOwner());
			if(Player == nullptr)
				return false;

			if(FootType == EPigFootType::None)
				return false;

			if (PigSoundDef == nullptr)
				return false;

			if(IsFootstep())
			{
				UPlayerFootstepTraceComponent TraceComp = UPlayerFootstepTraceComponent::Get(Player);

				FHazeTraceSettings Trace;
				Trace.TraceWithPlayer(Player);
				
				const FName TraceSocket = GetTraceSocketName();
				const FVector TraceStart = Player.Mesh.GetSocketLocation(TraceSocket);
				const FVector TraceEnd = TraceStart + (Player.Mesh.GetSocketRotation(TraceSocket).ForwardVector * TRACE_LENGTH);

				FHitResult Hit;
				if(!TraceComp.PerformTrace_Sphere(TraceStart, TraceEnd, Hit))
					return false;

				FPigFootstepParams Params;
				Params.FootType = FootType;
				Params.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(Hit, Trace));
		
				// Slope Tilt
				const FVector ForwardVeloDir = TraceComp.MoveComp.Velocity.ConstrainToPlane(TraceComp.MoveComp.WorldUp).GetSafeNormal();

				const float Sign = Math::Sign(TraceComp.MoveComp.Velocity.Z - ForwardVeloDir.Z);
				float TiltDeg = Math::DotToDegrees(TraceComp.MoveComp.Velocity.GetSafeNormal().DotProduct(ForwardVeloDir));

				TiltDeg *= Sign;

				Params.SlopeTilt = Math::GetMappedRangeValueClamped(FVector2D(-SLOPE_TILT_MAX_ANGLE, SLOPE_TILT_MAX_ANGLE), FVector2D(-1.0, 1.0), TiltDeg);

				if(IsFrontLeg())
					PigSoundDef.OnFootstep_Front(Params);
				else
					PigSoundDef.OnFootstep_Back(Params);
			}
			else
			{
				FPigJumpLandParams JumpLandParams;
				const float VerticalVeloSpeed = PigSoundDef.GetFallingSpeed();
				const float NormalizedVerticalVeloSpeed = Math::GetMappedRangeValueClamped(FVector2D(0, LANDING_VELOCITY_NORMALIZE_RANGE), FVector2D(0, 1), VerticalVeloSpeed);

				JumpLandParams.Intensity = NormalizedVerticalVeloSpeed;

				// FTundraMonkeyFootstepDatas FootstepDatas;
				// PigSoundDef.FootstepEvents.Find(AudioPhysMat.HardnessType, FootstepDatas);

				switch(FootType)
				{
					case(EPigFootType::Jump):
					{
						//JumpLandParams.SurfaceEvent = FootstepDatas.JumpEvent;
						PigSoundDef.OnFootstep_Jump(JumpLandParams);
						break;
					}
					case(EPigFootType::Land):
					{
						//JumpLandParams.SurfaceEvent = FootstepDatas.LandEvent;
						PigSoundDef.OnFootstep_Land(JumpLandParams);
						break;
					}	
					default: break;		
				}	
			}			

			return true;
		}
		const bool IsFootstep() const
		{
			return int(FootType) <= 4;
		}

		const bool IsFrontLeg() const
		{
			return FootType == EPigFootType::FrontLeft || FootType == EPigFootType::FrontRight;
		}

		const FName GetTraceSocketName() const
		{
			switch(FootType)
			{
				case(EPigFootType::FrontLeft): return MovementAudio::Pigs::FrontLeftFootSocketName; 
				case(EPigFootType::FrontRight): return MovementAudio::Pigs::FrontRightFootSocketName; 
				case(EPigFootType::BackLeft): return MovementAudio::Pigs::BackLeftFootSocketName; 
				case(EPigFootType::BackRight): return MovementAudio::Pigs::BackRightFootSocketName; 
				default: break;
			}

			return NAME_None;
		}
}