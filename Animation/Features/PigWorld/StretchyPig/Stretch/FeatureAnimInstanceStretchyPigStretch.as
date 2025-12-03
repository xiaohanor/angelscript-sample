UCLASS(Abstract)
class UFeatureAnimInstanceStretchyPigStretch : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureStretchyPigStretch Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureStretchyPigStretchAnimData AnimData;

	UHazeMovementComponent MoveComp;
	UPlayerPigStretchyLegsComponent StretchyLegsComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnterFailed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float EnterFailHeight;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		StretchyLegsComp = UPlayerPigStretchyLegsComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureStretchyPigStretch NewFeature = GetFeatureAsClass(ULocomotionFeatureStretchyPigStretch);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		EnterFailHeight = StretchyLegsComp.EnterFailHeight;
		bEnterFailed = StretchyLegsComp.bEnterFailed;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		bExit = LocomotionAnimationTag != Feature.Tag;

		Speed = MoveComp.Velocity.Size();



	}



	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return IsTopLevelGraphRelevantAnimFinished() && (TopLevelGraphRelevantStateName == n"Exit" || TopLevelGraphRelevantStateName == n"EnterFailed");
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
