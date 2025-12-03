UCLASS(Abstract)
class UFeatureAnimInstanceShockwaveArrow : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureShockwaveArrow Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureShockwaveArrowAnimData AnimData;

	// Add Custom Variables Here


	//Turns true when intiating left-handed throw (right side of screen when facing Rader)
	UPROPERTY()
	bool bStartLeftHandThrow;

	//Turns true when intiating right-handed throw (left side of screen when facing Rader)
	UPROPERTY()
	bool bStartRightHandThrow;

	//Turns true when exiting phase
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
		ULocomotionFeatureShockwaveArrow NewFeature = GetFeatureAsClass(ULocomotionFeatureShockwaveArrow);
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

		bStartLeftHandThrow = Rader.LastShootLeftHandFrame >= GFrameNumber-1;
		bStartRightHandThrow = Rader.LastShootRightHandFrame >= GFrameNumber-1;
		bPhaseFinished = Rader.CurrentAttack != EMeltdownPhaseOneAttack::ShockwaveArrow;
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
