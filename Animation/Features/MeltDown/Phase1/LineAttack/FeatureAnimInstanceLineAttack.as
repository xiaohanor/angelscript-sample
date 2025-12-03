UCLASS(Abstract)
class UFeatureAnimInstanceLineAttack : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureLineAttack Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureLineAttackAnimData AnimData;

	// Add Custom Variables Here

	//Rader attacks with his left hand, "screen" right
	UPROPERTY()
	bool bLeftHandAttack = false;

	//Rader attacks with his right hand, "screen" left
	UPROPERTY()
	bool bRightHandAttack = false;
	
	//Value between -1 and 1 for where the target is compared to Rader. -1 "screen" left, 1 "screen" right.
	UPROPERTY()
	float HandTrackingValue;

	//EXPERIMENT. Value between -1 and 1 for where the Rader is moving compared to where he is right now. -1 "screen" left, 1 "screen" right. I picture a position being set by design/code, Rader moves there sideways, stops, repeat. This value can then be used to trigger additive animations playing on top whatever else Rader is doing instead of doing variations for everything.
	UPROPERTY()
	float RaderMoveDirection;

	UPROPERTY()
	float InterpolatedRaderMoveDirection;

	//Becomes true when the phase is over
	UPROPERTY()
	bool bPhaseFinished = false;

	AMeltdownBossPhaseOne Rader;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		Rader = Cast<AMeltdownBossPhaseOne>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureLineAttack NewFeature = GetFeatureAsClass(ULocomotionFeatureLineAttack);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2f;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bPhaseFinished = Rader.CurrentAttack != EMeltdownPhaseOneAttack::Line;
		bLeftHandAttack = Rader.LastShootLeftHandFrame >= GFrameNumber-1;
		bRightHandAttack = Rader.LastShootRightHandFrame >= GFrameNumber-1;
		HandTrackingValue = Rader.LeftHandTrackingValue;
		RaderMoveDirection = Rader.LateralVelocity;

		// if (RaderMoveDirection > 0.75 || RaderMoveDirection < -0.75)
		// {
			InterpolatedRaderMoveDirection = Math::FInterpTo(InterpolatedRaderMoveDirection, RaderMoveDirection, DeltaTime, 2);
		// }
		// else
		// 	InterpolatedRaderMoveDirection = RaderMoveDirection;

		
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
}
