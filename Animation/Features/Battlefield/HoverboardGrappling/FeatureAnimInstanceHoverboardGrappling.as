UCLASS(Abstract)
class UFeatureAnimInstanceHoverboardGrappling : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboardGrappling Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardGrapplingAnimData AnimData;

	UPlayerMovementComponent MoveComponent;
	UBattlefieldHoverboardGrappleComponent GrappleComponent;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerGrappleAnimData GrappleAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FBattlefieldHoverboardAnimationParams HoverboardParams;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DistanceToTarget;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InitialDistanceToTarget;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HeightDifference;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InitialHeightDifference;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	bool bIsThrowing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float UpSideDownRatio;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InitialAngleDiff;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float GrappleDiffValue = 45;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float GrappleUpsideDownDiffValue = 0.05;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	const float LongDistanceToTargetTreashold = 3000;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector GrappleWorldPos;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ArmAimAlpha;

	float StartCalculatingArmAimAlpha;

	bool bHasLeftThrowState;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		MoveComponent = UPlayerMovementComponent::GetOrCreate(Player);
		GrappleComponent = UBattlefieldHoverboardGrappleComponent::GetOrCreate(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::GetOrCreate(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverboardGrappling NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboardGrappling);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bIsThrowing = false;

		ArmAimAlpha = 0;
		StartCalculatingArmAimAlpha = 0;

		bHasLeftThrowState = false;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		HoverboardParams = HoverboardComp.AnimParams;

		GrappleAnimData = GrappleComponent.AnimData;

		DistanceToTarget = GrappleComponent.DistToTarget;

		HeightDifference = GrappleComponent.AnimData.HeightDiff;

		if (CheckValueChangedAndSetBool(bIsThrowing, GrappleComponent.AnimData.bInEnter, TriggerDirection = EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			const FTransform HipsTransform = Player.Mesh.GetSocketTransform(n"Hips");

			UpSideDownRatio = HipsTransform.InverseTransformVector(MoveComponent.WorldUp).DotProduct(MoveComponent.WorldUp);

			// const FTransform BoardTransform = Player.Mesh.GetSocketTransform(n"LeftHand_IK"); //If I Want to use Hoverboard instead.
			const FTransform BoardTransform = Player.Mesh.GetSocketTransform(n"Hips"); // If I want to use hips instead.

			const FVector PlayerToGrappleDir = (GrappleComponent.Data.CurrentGrapplePoint.WorldLocation - HazeOwningActor.ActorLocation).GetSafeNormal();
			const FVector BoardDirectionGrappleDiffFlat = BoardTransform.InverseTransformVectorNoScale(PlayerToGrappleDir).VectorPlaneProject(Player.ActorUpVector).GetSafeNormal();
			// InitialAngleDiff = FRotator::MakeFromXZ(BoardDirectionGrappleDiffFlat, Player.ActorUpVector).Yaw; //If I Want to use Hoverboard instead.
			InitialAngleDiff = FRotator::MakeFromYZ(-BoardDirectionGrappleDiffFlat, Player.ActorUpVector).Yaw; // If I want to use Hips instead.

			GrappleWorldPos = GrappleComponent.Data.CurrentGrapplePoint.WorldLocation;

			InitialDistanceToTarget = (GrappleComponent.Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation).Size();
		}

		if (StartCalculatingArmAimAlpha > 0.2)
		{
			if (bHasLeftThrowState)
				ArmAimAlpha = Math::Clamp(ArmAimAlpha - DeltaTime / 0.05, 0.0, 0.85);
			else
				ArmAimAlpha = Math::Clamp(ArmAimAlpha + DeltaTime / 0.2, 0.0, 0.85);
		}

		else
			StartCalculatingArmAimAlpha += DeltaTime / 0.7;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (GetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered))
			return true;

		if (LocomotionAnimationTag != n"HoverboardAirMovement")
			return true;

		return LowestLevelGraphRelevantAnimTimeRemaining < 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

	UFUNCTION()
	void AnimNotify_LeftThrowState()
	{
		bHasLeftThrowState = true;
	}
}
