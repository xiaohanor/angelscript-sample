UCLASS(Abstract)
class UFeatureAnimInstanceSeekSlam : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSeekSlam Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSeekSlamAnimData AnimData;

	// Add Custom Variables Here


	//Value between -1 and 1 for where the target is compared to Rader. -1 "screen" left, 1 "screen" right.
	UPROPERTY()
	float LeftHandTrackingValue;

	//Value between -1 and 1 for where the target is compared to Rader. -1 "screen" left, 1 "screen" right.
	UPROPERTY()
	float RightHandTrackingValue;

	//Not used in the ABP, just set in the AnimInstance right now by checking if the phase start animation is done so that there are no additive animations played during it
	bool bStartCalculatingHandAlpha;

	UPROPERTY()
	float AdditiveHandsAlpha;

	//Becomes true when the attack position is locked
	UPROPERTY()
	bool bSlamAnticipate;

	//Becomes true when Rader attacks
	UPROPERTY()
	bool bSlam;

	//Becomes true when the phase is done
	UPROPERTY()
	bool bPhaseFinished;

	AMeltdownBossPhaseOne Rader;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

		Rader = Cast<AMeltdownBossPhaseOne>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSeekSlam NewFeature = GetFeatureAsClass(ULocomotionFeatureSeekSlam);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bStartCalculatingHandAlpha = false;

		AdditiveHandsAlpha = 0;
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

		// Implement Custom Stuff Here

		AdditiveHandsAlpha = Math::FInterpTo(AdditiveHandsAlpha, 1, DeltaTime, 2);

		bSlamAnticipate = Rader.LastSlamAnticipateFrame >= GFrameNumber-1;
		bSlam = Rader.LastSlamFrame >= GFrameNumber-1;
		LeftHandTrackingValue = Rader.LeftHandTrackingValue;
		RightHandTrackingValue = Rader.RightHandTrackingValue;

		bPhaseFinished = Rader.CurrentAttack != EMeltdownPhaseOneAttack::SeekSlam;
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
	void AnimNotify_PhaseStartFinished()
	{
		bStartCalculatingHandAlpha = true;
	}
}


