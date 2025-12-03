UCLASS(Abstract)
class UFeatureAnimInstanceShapeshift : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureShapeshift Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureShapeShiftData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData BasePose;

	UPROPERTY(BlueprintHidden)
	UHazeBoneFilterAsset BoneFilterFullBody;

	UPROPERTY(BlueprintHidden)
	UHazeBoneFilterAsset BoneFilterNull;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Otter")
	bool bIsOtterTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Otter")
	bool bIsOtter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTransformingToSelf;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasValidScaleAdditive;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ScaleAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CorrectionPoseAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Transform Anim")
	UAnimSequence TransformAnim;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Transform Anim")
	bool bPlayTransformAnim;
	bool bWantsToPlayTransformAnim = true;

	AHazePlayerCharacter PlayerRef;
	UHazeCharacterSkeletalMeshComponent CurrentMesh;

	UTundraPlayerShapeshiftingComponent ShapeShiftComp;
	UPlayerMovementComponent MoveComp;
	UHazeAnimCopyPoseFromMeshComponent CopyMeshComp;

	ETundraShapeshiftShape PreviousShapeType;
	ETundraShapeshiftShape CurrentShapeType;

	int TickActive = 0;
	bool bInterupMorph;
	float ShapeshiftAlpha;



	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		bIsPlayer = Player != nullptr;
		PlayerRef = bIsPlayer ? Player : Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);

		bIsOtter = Cast<ATundraPlayerOtterActor>(HazeOwningActor) != nullptr;

		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(PlayerRef);
		MoveComp = UPlayerMovementComponent::Get(PlayerRef);
		CopyMeshComp = UHazeAnimCopyPoseFromMeshComponent::GetOrCreate(HazeOwningActor);
	}


	FHazeCopyPoseFromMeshRetargetOption CreateRetargetOption(FName BoneName, FRotator Rotation)
	{
		auto NewOption = FHazeCopyPoseFromMeshRetargetOption();
		NewOption.BoneName = BoneName;
		NewOption.LocalSpaceOffset = FTransform(Rotation);

		return NewOption;
	}


	void SetupRetargetOptions()
	{
		if (CopyMeshComp == nullptr)
			return;

		TArray<FHazeCopyPoseFromMeshRetargetOption> RetargetOptions;
		RetargetOptions.Reset();

		if (bIsOtterTransform)
		{
			if (bIsOtter)
			{
				const FRotator NeckRotation = FRotator(0, 150, 0);
				const FRotator HipsToSpine2Rotation = FRotator(180, 0, 0);
				const FRotator Spine3AndSpine4Rotation = FRotator(90, 0, 0);

				RetargetOptions.Add(CreateRetargetOption(n"Spine4", Spine3AndSpine4Rotation));
				RetargetOptions.Add(CreateRetargetOption(n"Spine3", Spine3AndSpine4Rotation));

				RetargetOptions.Add(CreateRetargetOption(n"Spine2", HipsToSpine2Rotation));
				RetargetOptions.Add(CreateRetargetOption(n"Spine", HipsToSpine2Rotation));
				RetargetOptions.Add(CreateRetargetOption(n"Hips", HipsToSpine2Rotation));

				RetargetOptions.Add(CreateRetargetOption(n"Neck", NeckRotation));
				RetargetOptions.Add(CreateRetargetOption(n"Neck1", NeckRotation));
				RetargetOptions.Add(CreateRetargetOption(n"Neck2", NeckRotation));

				RetargetOptions.Add(CreateRetargetOption(n"Head", FRotator(90, 180, 0)));
			}

			else
			{
				const FRotator SpineRotation = FRotator(0, 180, 180);
				const FRotator NeckRotation = FRotator(0, 180, 0);

				RetargetOptions.Add(CreateRetargetOption(n"Hips", SpineRotation));
				RetargetOptions.Add(CreateRetargetOption(n"Spine", SpineRotation));
				RetargetOptions.Add(CreateRetargetOption(n"Spine1", SpineRotation));
				RetargetOptions.Add(CreateRetargetOption(n"Spine2", SpineRotation));

				RetargetOptions.Add(CreateRetargetOption(n"Neck", NeckRotation));
				RetargetOptions.Add(CreateRetargetOption(n"Neck1", NeckRotation));

				RetargetOptions.Add(CreateRetargetOption(n"Head", FRotator(90, 180, 0)));
			}
		}

		CopyMeshComp.SetRetargetOptions(RetargetOptions);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		InternalInit();
	}

	void InternalInit()
	{
		Feature = GetFeatureAsClass(ULocomotionFeatureShapeshift);
		if (Feature == nullptr)
			return;
		
		TickActive = 0;

		if (GetAnimBoolParam(n"FailMorphSwapDir", true))
		{
			PreviousShapeType = ShapeShiftComp.GetAnimationTargetShapeType();
			CurrentShapeType = ShapeShiftComp.GetAnimationPreviousShapeType();
		}
		else
		{
			CurrentShapeType = ShapeShiftComp.GetAnimationTargetShapeType();
			PreviousShapeType = ShapeShiftComp.GetAnimationPreviousShapeType();
		}

		CurrentMesh = ShapeShiftComp.GetMeshForShapeType(CurrentShapeType);
		auto PreviousMesh = ShapeShiftComp.GetMeshForShapeType(PreviousShapeType);

		bTransformingToSelf = CurrentMesh == OwningComponent;

		// Get the AnimData
		const auto SourceShapeType = bTransformingToSelf ? PreviousShapeType : CurrentShapeType;
		AnimData = Feature.GetAnimDataForShape(SourceShapeType);
		BasePose = Feature.BasePose;

		// Set the source mesh
		auto SourcePoseMesh = bTransformingToSelf ? PreviousMesh : CurrentMesh;
		CopyMeshComp.SetSourceMeshComponent(SourcePoseMesh);

		// TODO: ScaleAlpha could be a curve as well ?

		bHasValidScaleAdditive = AnimData.ScalePose != nullptr;

		bIsOtterTransform = bIsOtter || (PlayerRef == Game::Mio && (CurrentShapeType == ETundraShapeshiftShape::Small || PreviousShapeType == ETundraShapeshiftShape::Small));

		bInterupMorph = GetAnimBoolParam(n"InterupedShapeShift", true);

		SetupRetargetOptions();

		bWantsToPlayTransformAnim = false;
		bPlayTransformAnim = false;
	}


	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		return 0;
	}


	UFUNCTION(BlueprintOverride)
	float32 GetBlendTimeWhenResetting() const
	{
		return 0.5;
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (ShapeShiftComp == nullptr)
			return;

		if (bTransformingToSelf)
		{
			// Delay the actual animation 1 tick, by first setting a `bWantsToPlayTransformAnim` that can still be read in the CanTransitionFrom rule
			if (bWantsToPlayTransformAnim && TickActive > 1)
				bPlayTransformAnim = true;

			else if (AnimData.TransformMh != nullptr && LocomotionAnimationTag == n"Movement")
				bWantsToPlayTransformAnim = true;
		}
		
		// Morph Alpha
		if (ShapeShiftComp.CurrentMorphDuration > 0)
			ShapeshiftAlpha = ShapeShiftComp.AnimData.MorphAlpha;
		else
			ShapeshiftAlpha = 1;

		// Correction pose alpha
		if (AnimData.CorrectionPose != nullptr)
		{
			if (bTransformingToSelf)
				CorrectionPoseAlpha = 1 - ShapeshiftAlpha;
			else
				CorrectionPoseAlpha = ShapeshiftAlpha * 1.3;
		}
		else
			CorrectionPoseAlpha = 0;

		// Scale Alpha
		if (bTransformingToSelf)
		{
			ScaleAlpha = 1 - ShapeshiftAlpha;
		}
		else
			ScaleAlpha = ShapeshiftAlpha * 1.3;

		if (OverrideFeatureTag != Feature.Tag)
			TickActive++;
	}

	UFUNCTION(BlueprintOverride)
	UHazeBoneFilterAsset GetOverrideBoneFilter(float32& OutBlendTime, bool& bOutUseMeshSpaceBlend) const
	{
		OutBlendTime = 0;

		// if we did a interup, keep running with the full body filter, so we don't pop into full size
		if (bInterupMorph)
			return BoneFilterFullBody;

		// If we're transitioning into a new mesh, use a
		// In theory we should be able to use TickActive 0 here, however there are some weird issues :( 
		if (!bTransformingToSelf && TickActive <= 2) 
			return BoneFilterNull;

		return BoneFilterFullBody;
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (bTransformingToSelf && (TickActive > 1 || bInterupMorph))
		{
			if (!bWantsToPlayTransformAnim)
				return true;
			
			if (LocomotionAnimationTag != n"Movement")
				return true;

			if (!MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero())
				return true;

			if (!bPlayTransformAnim)
				return false;

			return IsTopLevelGraphRelevantAnimFinished();
		}

		return ShapeshiftAlpha >= 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnWantToTransitionFrom()
	{
	}


	UFUNCTION(BlueprintOverride)
	float32 GetBlendTimeToNullFeature() const
	{
		if (bPlayTransformAnim)
		{
			if (IsTopLevelGraphRelevantAnimFinished())
				return 0.9;
		}

		return GetShapeshiftBlendOutTime();
	}

	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
	float32 GetShapeshiftBlendOutTime() const
	{
		if (bTransformingToSelf)
		{
			return Math::Max(float32(ShapeShiftComp.CurrentMorphDuration * (1 - ShapeshiftAlpha)), 0.2);
		}

		return 0;
	}


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		bool bIsTransitioningToMovement = LocomotionAnimationTag == n"Movement" || LocomotionAnimationTag == n"TreeGuardianStrafe";

		if (bTransformingToSelf && !bPlayTransformAnim) 
		{
			// Reset the sub-animinstance to have force re-initialize so they fetch e.g. SkipStart bools etc.
			CurrentMesh.ResetSubAnimationInstance(EHazeAnimInstEvalType::Feature);

			if (bIsTransitioningToMovement && !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero())
				SetAnimBoolParam(HazeAnimParamTags::SkipMovementStart, true);
		
			if (CurrentShapeType == ETundraShapeshiftShape::Player)
			{
				// If we're transforming back to the player
				if (bIsPlayer)
				{
					if (bIsTransitioningToMovement)
					{
						SetAnimFloatParam(n"BlendIkSpeed", 1.5);
					}
				}
			}
		
		}
	}


	UFUNCTION(BlueprintOverride)
	void LogAnimationTemporalData(FTemporalLog& TemporalLog) const
	{
		TemporalLog.Value("ShapeshiftAlpha", ShapeshiftAlpha);
		TemporalLog.Value("CorrectionPoseAlpha", CorrectionPoseAlpha);
		TemporalLog.Value("ScaleAlpha", ScaleAlpha);
		TemporalLog.Value("bTransformingToSelf", bTransformingToSelf);
		TemporalLog.Value("TickActive", TickActive);
		TemporalLog.Value("bInterupMorph", bInterupMorph);
		
	}
}
