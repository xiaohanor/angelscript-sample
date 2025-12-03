UCLASS(Abstract)
class UFeatureAnimInstanceSlideChase : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSlideChase Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSlideChaseAnimData AnimData;

	// Add Custom Variables Here


	//True if Rader moves along the spline, false if he is waiting for the players
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	//Rader's rotation along the spline when it curve, with -1 to screen left, 0 neutral, 1 screen right
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float SplineCurveValue;

	//Attack, to become true the frame an obstacle is spawned. Thinking it should just be true for a short while so that it can reset the attack state if multiple attacks happen in a short timespan
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttack;

	//When the players reach the end of the spline and Rader removes the floor. Maybe should be a Level Sequence to more easily time things with other departments, but for now I think we can just put it in the ABP
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPhaseFinished;

	AMeltdownBossPhaseOne Rader;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSlideChase NewFeature = GetFeatureAsClass(ULocomotionFeatureSlideChase);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		Rader = Cast<AMeltdownBossPhaseOne>(HazeOwningActor);
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

		if (IsValid(Rader))
		{
			bAttack = Rader.LastSlideAttackFrame >= GFrameNumber-1;
			bIsMoving = Rader.bSlideMoving;
			bPhaseFinished = !Rader.bSlideMoving;
			SplineCurveValue = Rader.SlideLeanValue;
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
}
