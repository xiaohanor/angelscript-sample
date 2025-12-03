// enum ELadderTopEnterType
// {
// 	FacingLadderForward,
// 	Clockwise,
// 	CounterClockwise,
// }

enum ELadderDashUpType
{
	None,
	Left,
	Right,
}

UCLASS(Abstract)
class UFeatureAnimInstanceLadderClimb : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureLadderClimb Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureLadderClimbAnimData AnimData;

	// Add Custom Variables Here
	UPlayerLadderComponent LadderClimbComponent;
	UPlayerMovementComponent MovementComponent;
	UAnimFootTraceComponent FootTraceComp;

	UPROPERTY()
	FPlayerLadderAnimData LadderAnimData;

	// UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	// ELadderTopEnterType TopEnterType;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ELadderDashUpType LadderDashUpType;

	UPROPERTY()
	bool bLeftFoot;

	UPROPERTY()
	bool bAirEnter;

	UPROPERTY()
	bool bExiting;

	UPROPERTY()
	bool bHasInput;

	UPROPERTY()
	bool bIsJumpingUp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedJumpingUp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedTransfer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWallRunEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float EnterAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKAlpha = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIK = true;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeSlopeWarpingData IKData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float SlopeAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput IKFeetPlacementData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIKFeetPlacement;

	bool bStartedTopEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bValidGroundExitFound;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		LadderClimbComponent = UPlayerLadderComponent::GetOrCreate(Player);
		MovementComponent = UPlayerMovementComponent::GetOrCreate(Player);
		FootTraceComp = UAnimFootTraceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureLadderClimb NewFeature = GetFeatureAsClass(ULocomotionFeatureLadderClimb);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bAirEnter = (GetPrevLocomotionAnimationTag() == n"AirMovement" || GetPrevLocomotionAnimationTag() == n"Jump");

		bLeftFoot = false;

		bIsJumpingUp = false;

		bStartedJumpingUp = false;

		LadderDashUpType = ELadderDashUpType::None;

		// IK Data
		FootTraceComp.InitializeTraceDataVariable(IKFeetPlacementData);
		bEnableIKFeetPlacement = false;
		bEnableIK = false;
		IKAlpha = 0;
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		LadderAnimData = LadderClimbComponent.AnimData;

		bLeftFoot = GetAnimBoolParam(n"LadderLeftFootUp", bConsume = false);

		bExiting = LadderAnimData.State == EPlayerLadderState::ExitOnBottom || LadderAnimData.State == EPlayerLadderState::ExitOnTop || LadderAnimData.State == EPlayerLadderState::LetGo || LadderAnimData.State == EPlayerLadderState::JumpOut;

		bHasInput = !MovementComponent.GetSyncedMovementInputForAnimationOnly().IsNearlyZero(0.1);

		bStartedJumpingUp = (CheckValueChangedAndSetBool(bIsJumpingUp, LadderAnimData.State == EPlayerLadderState::Dash, EHazeCheckBooleanChangedDirection::FalseToTrue));
		bStartedTransfer = (CheckValueChangedAndSetBool(bStartedTransfer, LadderAnimData.bTransferUpInitiated, EHazeCheckBooleanChangedDirection::FalseToTrue));
		LadderClimbComponent.AnimData.bTransferUpInitiated = false;

		// if (CheckValueChangedAndSetBool(bStartedTopEnter, LadderAnimData.State == ELadderStates::EnterFromTop, EHazeCheckBooleanChangedDirection::FalseToTrue))
		// {

		// }

		bWallRunEnter = LadderClimbComponent.bEnteredFromWallrun;

		EnterAngle = LadderClimbComponent.EnterAngle;

		bValidGroundExitFound = LadderClimbComponent.AnimData.bValidGroundExitFound;

		// IK Data
		if (bExiting && (LadderAnimData.State == EPlayerLadderState::ExitOnBottom || LadderAnimData.State == EPlayerLadderState::ExitOnTop))
			bEnableIK = true;

		if (bEnableIK)
		{
			if (LadderAnimData.State != EPlayerLadderState::Inactive && LadderAnimData.State != EPlayerLadderState::ExitOnBottom && LadderAnimData.State != EPlayerLadderState::ExitOnTop)
			{
				bEnableIKFeetPlacement = false;
				bEnableIK = false;
				IKAlpha = 0;
			}
			else
			{
				IKAlpha = Math::FInterpConstantTo(IKAlpha, 1, DeltaTime, 5);
				FootTraceComp.UpdateSlopeWarpData(IKData);
				SlopeAngle = MovementComponent.GetSlopeRotationForAnimation().Pitch;
				const bool bForceReTraceAllFeet = CheckValueChangedAndSetBool(bEnableIKFeetPlacement,
																			FootTraceComp.AreRequirementsMet(),
																			EHazeCheckBooleanChangedDirection::TrueToFalse);
				if (bEnableIKFeetPlacement)
					FootTraceComp.TraceFeet(IKFeetPlacementData, bForceReTraceAllFeet);
			}
		}

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}

	UFUNCTION()
	void AnimNotify_JumpUpLeft()
	{
		LadderDashUpType = ELadderDashUpType::Right;
	}

	UFUNCTION()
	void AnimNotify_JumpUpRight()
	{
		LadderDashUpType = ELadderDashUpType::Left;
	}

	UFUNCTION()
	void AnimNotify_IsClimbingUp()
	{
		LadderDashUpType = ELadderDashUpType::None;
	}
}
