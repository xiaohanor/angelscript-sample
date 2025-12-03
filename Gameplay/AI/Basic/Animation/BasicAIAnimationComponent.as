
struct FBasicAIAnimationActionDurations
{
	float Telegraph = 0.0;
	float Anticipation = 0.0;
	float Action = 0.0;
	float Recovery = 0.0;

	void ScaleAll(float TimeScale)
	{
		Telegraph *= TimeScale;
		Anticipation *= TimeScale;
		Action *= TimeScale;
		Recovery *= TimeScale;
	}

	bool IsValid() const
	{
		return (Telegraph > 0.0) || (Anticipation > 0.0) || (Action > 0.0) || (Recovery > 0.0);
	}

	bool IsFullySet() const
	{
		return (Telegraph > 0.0) && (Anticipation > 0.0) && (Action > 0.0) && (Recovery > 0.0);
	}

	float GetTotal() const
	{
		return Telegraph + Anticipation + Action + Recovery;
	}

	bool IsBeforeAction(float Time)
	{
		return Time < Telegraph + Anticipation;
	}

	bool IsInActionRange(float Time)
	{
		if (Time < Telegraph + Anticipation)
			return false;
		if (Time > Telegraph + Anticipation + Action)
			return false;
		// In time interval between anticipation and recovery 
		return true;
	} 

	bool IsInRecoveryRange(float Time)
	{
		return (Time > Telegraph + Anticipation + Action);
	}

	bool IsInAnticipationRange(float Time)
	{
		return (Time > Telegraph) && (Time < Telegraph + Anticipation);
	}

	bool IsInTelegraphRange(float Time)
	{
		return (Time < Telegraph);
	}
	
	float GetTelegraphRangeAlpha(float Time)
	{
		if(Telegraph == 0)
			return 0;
		float Alpha = Time / Telegraph;
		return Math::Clamp(Alpha, 0, 1);
	}
	
	float GetAnticipationRangeAlpha(float Time)
	{
		if(Anticipation == 0)
			return 0;
		float Alpha = (Time - Telegraph) / Anticipation;
		return Math::Clamp(Alpha, 0, 1);
	}
	
	float GetActionRangeAlpha(float Time)
	{
		if(Action == 0)
			return 0;
		float Alpha = (Time - Telegraph - Anticipation) / Action;
		return Math::Clamp(Alpha, 0, 1);
	}

	float GetRecoveryRangeAlpha(float Time)
	{
		if(Recovery == 0)
			return 0;
		float Alpha = (Time - Telegraph - Anticipation - Action) / Recovery;
		return Math::Clamp(Alpha, 0, 1);
	}

	float GetPreActionDuration() const property
	{
		return Telegraph + Anticipation;
	}

	float GetPreRecoveryDuration() const property
	{
		return Telegraph + Anticipation + Action;
	}
}

struct FBasicAIAnimationFeatureData
{
	FName Tag;
	FName SubTag;
	FInstigator Instigator;
	EBasicBehaviourPriority Priority;
	float Duration;
	FBasicAIAnimationActionDurations ActionDurations;
	FVector RequestedLocalMovement;
	bool bUseLocalMovementRotation;

	void Reset(FName DefaultTag)
	{
		Tag = DefaultTag;
		SubTag = NAME_None;
		Instigator = nullptr;
		Priority = EBasicBehaviourPriority::Minimum;
		Duration = 0;
		ActionDurations = FBasicAIAnimationActionDurations();
		RequestedLocalMovement = FVector(BIG_NUMBER);
	}
}

struct FBasicAIOverrideFeatureData
{
	FName Tag;
	FInstigator Instigator;

	void Reset()
	{
		Tag = NAME_None;
		Instigator = nullptr;
	}
}

class UBasicAIAnimationComponent : UActorComponent
{
	AHazeActor HazeOwner;

	UPROPERTY()
	FName BaseMovementTag = LocomotionFeatureAITags::StrafeMovement;

	UPROPERTY()
	bool bIsAiming = false;

	// Actor local forward movement speed (units per second)
	UPROPERTY()
	float SpeedForward = 0.0;

	// Actor local rightward movement speed (units per second), negative value if moving to our left)
	UPROPERTY()
	float SpeedRight = 0.0;

	// Actor local upward movement speed (units per second), negative value if moving down)
	UPROPERTY()
	float SpeedUp = 0.0;


	// How fast (degrees per second) we currently turn. Positive values when turning to the right, negative when turning to the left.
	UPROPERTY()
	float TurnRate = 0.0;

	// How fast (degrees per second) we currently changing pitch. Positive values when pitching upwards, negative when downwards.
	UPROPERTY()
	float PitchRate = 0.0;

	TInstigated<float> AimPitch;
	TInstigated<float> AimYaw;

	FRotator PrevRot;

	// Feature which we will be requesting currently
	private FBasicAIAnimationFeatureData CurrentFeature;
	
	UHazeCharacterSkeletalMeshComponent CharacterMesh;

	UBasicAITargetingComponent TargetComp;

	FVector MovementDelta;

	private FBasicAIOverrideFeatureData OverrideFeature;

	bool bInitialReset = true;
	
	TMap<UAnimSequenceBase, float> ActionPlayRate;
	TMap<UBlendSpace, float> BlendSpaceActionPlayRate;

	// Current accelerated default aim blend space values in actor local space
	private FHazeAcceleratedRotator AccAim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		CharacterMesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
		TargetComp = UBasicAITargetingComponent::GetOrCreate(Owner);
		AimPitch.DefaultValue = 0.0;
		AimYaw.DefaultValue = 0.0;
		AccAim.SnapTo(FRotator::ZeroRotator);
		Reset();
	}

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		PrevRot = Owner.ActorRotation;
		CurrentFeature.Reset(BaseMovementTag);
		OverrideFeature.Reset();
		if (!bInitialReset && CharacterMesh.SkeletalMeshAsset != nullptr)
			CharacterMesh.ResetAllAnimation();
		bInitialReset = false;
	}

	void SetBaseAnimationTag(FName AnimTag, FInstigator Instigator)
	{
		BaseMovementTag = AnimTag;
		if ((CurrentFeature.Instigator == nullptr) || (CurrentFeature.Instigator == Instigator))
			CurrentFeature.Reset(BaseMovementTag);
	}

	void Update(float DeltaTime)
	{
		SpeedForward = HazeOwner.ActorVelocity.DotProduct(HazeOwner.ActorForwardVector);		
		SpeedRight = HazeOwner.ActorVelocity.DotProduct(HazeOwner.ActorRightVector);
		SpeedUp = HazeOwner.ActorVelocity.DotProduct(HazeOwner.ActorUpVector);

		if (TargetComp.HasValidTarget())
		{
			FVector AimAtLocation = (TargetComp.Target.ActorCenterLocation + TargetComp.Target.FocusLocation) * 0.5;
			FVector WorldAimDir = AimAtLocation - HazeOwner.FocusLocation;
			FRotator LocalAimRot = Owner.ActorTransform.InverseTransformVector(WorldAimDir).Rotation();
			AccAim.AccelerateTo(LocalAimRot, 0.5, DeltaTime);
		}
		else
		{
			AccAim.AccelerateTo(FRotator::ZeroRotator, 1.0, DeltaTime);
		}

		AimPitch.Apply(AccAim.Value.Pitch, this, EInstigatePriority::Low);
		AimYaw.Apply(AccAim.Value.Yaw, this, EInstigatePriority::Low);

		if (DeltaTime > 0.0)
		{
			FRotator CurRot = Owner.ActorRotation;
			if (Owner.ActorUpVector.DotProduct(FVector::UpVector) > 0.9999)
			{
				// Common case to avoid unnecessary transforming
				TurnRate = FRotator::NormalizeAxis(CurRot.Yaw - PrevRot.Yaw) / DeltaTime;
				PitchRate = FRotator::NormalizeAxis(CurRot.Pitch - PrevRot.Pitch) / DeltaTime;
			}
			else
			{
				// Not aligned with world, turn/pitchrate should be in local rotation.
				FRotator InverseDelta = Owner.ActorTransform.InverseTransformRotation(PrevRot).GetNormalized(); 
				TurnRate = -InverseDelta.Yaw / DeltaTime;
				PitchRate = -InverseDelta.Pitch / DeltaTime;
			}
			PrevRot = CurRot;
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsMoving()
	{
		return (Math::Abs(SpeedForward) > 10.0) || (Math::Abs(SpeedRight) > 10.0);
	}

	// Call with a duration to request feature for that many seconds or call every tick when it should run indefinitely.
	void RequestFeature(FName Tag, EBasicBehaviourPriority Priority, FInstigator Instigator, float Duration = 0.0, FVector RequestedMovement = FVector(BIG_NUMBER), bool bUseLocalMovementRotation = false)
	{
		RequestFeature(Tag, NAME_None, Priority, Instigator, Duration, RequestedMovement, bUseLocalMovementRotation);
	}

	void RequestFeature(FName Tag, FName SubTag, EBasicBehaviourPriority Priority, FInstigator Instigator, float Duration = 0.0, FVector RequestedMovement = FVector(BIG_NUMBER), bool bUseLocalMovementRotation = false)
	{
		// Latest applied takes precedence at same prio
		if ((Priority >= CurrentFeature.Priority) || (CurrentFeature.Instigator == Instigator))		
		{
			CurrentFeature.Tag = Tag;
			CurrentFeature.SubTag = SubTag;
			CurrentFeature.Instigator = Instigator;
			CurrentFeature.Priority = Priority;
			CurrentFeature.Duration = Duration;
			if (RequestedMovement != FVector(BIG_NUMBER))
				CurrentFeature.RequestedLocalMovement = CharacterMesh.WorldTransform.InverseTransformVectorNoScale(RequestedMovement);
			CurrentFeature.ActionDurations = FBasicAIAnimationActionDurations();
			CurrentFeature.bUseLocalMovementRotation = bUseLocalMovementRotation;

			FTemporalLog TemporalLog = TEMPORAL_LOG(this, "AI Anim Comp");

			TemporalLog.Value("Instigator", Instigator);
			TemporalLog.Value("CurrentFeatureTag", CurrentFeature.Tag);
		}


	}

	void RequestSubFeature(FName SubTag, FInstigator Instigator, float Duration = 0.0)
	{
		if (CurrentFeature.Instigator == Instigator)
		{
			CurrentFeature.SubTag = SubTag;
			CurrentFeature.Duration = Duration;
		}
	}

	void RequestAction(FName Tag, EBasicBehaviourPriority Priority, FInstigator Instigator, FBasicAIAnimationActionDurations Durations, FVector RequestedMovement = FVector(BIG_NUMBER), bool bUseLocalMovementRotation = false)
	{
		RequestAction(Tag, NAME_None, Priority, Instigator, Durations, RequestedMovement, bUseLocalMovementRotation);
	}

	void RequestAction(FName Tag, FName SubTag, EBasicBehaviourPriority Priority, FInstigator Instigator, FBasicAIAnimationActionDurations Durations, FVector RequestedMovement = FVector(BIG_NUMBER), bool bUseLocalMovementRotation = false)
	{
		RequestFeature(Tag, SubTag, Priority, Instigator, Durations.GetTotal(), RequestedMovement, bUseLocalMovementRotation);
		if (CurrentFeature.Instigator == Instigator)
			CurrentFeature.ActionDurations = Durations;
	}

	void RequestOverrideFeature(FName Tag, FInstigator Instigator)
	{
		OverrideFeature.Tag = Tag;
		OverrideFeature.Instigator = Instigator;
	}

	void ClearFeature(FInstigator Instigator)
	{
		if (CurrentFeature.Instigator == Instigator)
			CurrentFeature.Reset(BaseMovementTag);
		if (OverrideFeature.Instigator == Instigator)
			OverrideFeature.Reset();

		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "AI Anim Comp");

			TemporalLog.Value("Clear Instigator", Instigator);
	}

	FName GetFeatureTag() const property
	{
		return CurrentFeature.Tag;		
	}

	FName GetSubFeatureTag() const property
	{
		return CurrentFeature.SubTag;		
	}

	FName GetOverrideFeatureTag() const property
	{
		return OverrideFeature.Tag;
	}

	float GetDurationRequest() const
	{
		return CurrentFeature.Duration;
	}

	bool HasDurationRequest() const
	{
		return (CurrentFeature.Duration != 0.0) || HasActionDurationRequest();
	}

	bool HasActionDurationRequest() const
	{
		return CurrentFeature.ActionDurations.IsValid();
	}

	FBasicAIAnimationActionDurations GetActionDurationRequest() const
	{
		return CurrentFeature.ActionDurations;
	}

	bool HasMovementRequest() const
	{
		return CurrentFeature.RequestedLocalMovement != FVector(BIG_NUMBER);
	}

	FVector GetMovementRequest() const
	{
		if (!HasMovementRequest())
			return FVector::ZeroVector;
		return CurrentFeature.RequestedLocalMovement;
	}

	bool IsUsingLocalMovementRotation() const
	{
		return CurrentFeature.bUseLocalMovementRotation;
	}

	// True if given feature tag and subtag is currently top prio
	bool HasPriority(FName Tag, FName SubTag)
	{
		if (CurrentFeature.Tag != Tag)
			return false;
		if (CurrentFeature.SubTag != SubTag)
			return false;
		return true;
	}

	// Will be true if tag matches, any subtag will do
	bool HasPriority(FName Tag)
	{
		if (CurrentFeature.Tag != Tag)
			return false;
		return true;
	}

	// True when we no longer are in given animation state	
	bool IsFinished(FName Tag, FName SubTag)
	{
		// ABP has cleared prio flag since it finished, or something else has grabbed prio
		return !HasPriority(Tag, SubTag);
	}

	// ABP should call this when done to let us know it's done
	void ClearPrioritizedFeatureTag(FName Tag)
	{
		if (CurrentFeature.Tag == Tag)
			CurrentFeature.Reset(BaseMovementTag);
	}

	void ClearAnimationMove(FName Tag)
	{
		if (CurrentFeature.Tag == Tag)
			CurrentFeature.RequestedLocalMovement = FVector(BIG_NUMBER);
	}

	UHazeLocomotionFeatureBase GetFeatureByClass(TSubclassOf<UHazeLocomotionFeatureBase> FeatureClass)
	{
		UHazeCharacterSkeletalMeshComponent Mesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
		if (Mesh == nullptr)
			return nullptr;
		
		return Mesh.GetFeatureByClass(FeatureClass);
	}	

	FVector GetCurrentMovementDelta()
	{
		return MovementDelta;
	}

	// Get expected duration of animation that requesting given tag/subtag would result in
	float GetAnimDuration(FName Tag, FName SubTag = NAME_None, float OverrideDuration = 0.0)
	{
		if (OverrideDuration > 0.0)
			return OverrideDuration;

		// TODO: This needs implementation!
		return 2.0;
	}

	float GetActionPlayRate(FHazePlaySequenceData Data)
	{
		return GetSequencePlayRate(Data.Sequence);
	}

	float GetBlendSpaceActionPlayRate(FHazePlayBlendSpaceData Data)
	{
		if (BlendSpaceActionPlayRate.Contains(Data.BlendSpace))
			return BlendSpaceActionPlayRate[Data.BlendSpace];
		return 1.0;
	}

	float GetSequencePlayRate(UAnimSequenceBase Sequence)
	{
		if (ActionPlayRate.Contains(Sequence))
			return ActionPlayRate[Sequence];
		return 1.0;
	}
}

