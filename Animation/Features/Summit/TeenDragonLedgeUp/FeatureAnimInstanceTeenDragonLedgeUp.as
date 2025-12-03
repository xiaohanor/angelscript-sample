UCLASS(Abstract)
class UFeatureAnimInstanceTeenDragonLedgeUp : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTeenDragonLedgeUp Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTeenDragonLedgeUpAnimData AnimData;


	UHazeMovementComponent MoveComp;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		auto PlayerRef = Player;  
		if (PlayerRef == nullptr)
		{
			PlayerRef = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
		}
		MoveComp = UHazeMovementComponent::Get(PlayerRef);		
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTeenDragonLedgeUp NewFeature = GetFeatureAsClass(ULocomotionFeatureTeenDragonLedgeUp);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

	}


	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.0;
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		bool bWantsToMoveLocal = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		// If any tag that's not movement is requested, leave this abp.
		if (LocomotionAnimationTag != n"Movement")
			return true;

		if (bWantsToMoveLocal)
			return true;

		// Finish playing the animation before leaving
		return IsTopLevelGraphRelevantAnimFinished();
	}


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"Movement" && TopLevelGraphRelevantStateName == n"LedgeUpJog")
		{
			SetAnimBoolParam(n"SkipMovementStart", true);
			SetAnimBlendTimeToMovement(HazeOwningActor, 0.1);
		}
	
	}
}
