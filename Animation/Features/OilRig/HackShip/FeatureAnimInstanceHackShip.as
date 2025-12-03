UCLASS(Abstract)
class UFeatureAnimInstanceHackShip : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHackShip Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHackShipAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform HijackPanelHandleTransform;

	AOilRigShipHijackPanel HijackPanel;
	UPlayerMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRightHandIK;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLeftHandIK;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurnKnob;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		auto InteractionsComp = UPlayerInteractionsComponent::Get(Player);
		if (InteractionsComp != nullptr)
			HijackPanel = Cast<AOilRigShipHijackPanel>(InteractionsComp.ActiveInteraction.Owner);

		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHackShip NewFeature = GetFeatureAsClass(ULocomotionFeatureHackShip);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (HijackPanel != nullptr)
			HijackPanelHandleTransform = HijackPanel.ButtonRoot.WorldTransform;

		bExit = LocomotionAnimationTag != Feature.Tag;

		bTurnKnob = GetAnimTrigger(n"TurnKnob");
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Movement")
			return true;

		if (TopLevelGraphRelevantStateName != n"Exit")
			return false;

		if (!MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero())
			return true;

		return IsTopLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

	UFUNCTION()
	void AnimNotify_EnableIK()
	{
		if (Feature.bIKRightHand)
			bRightHandIK = true;
		else
			bLeftHandIK = true;
	}

	UFUNCTION()
	void AnimNotify_DisableIK()
	{
		bRightHandIK = false;
		bLeftHandIK = false;
	}
}
