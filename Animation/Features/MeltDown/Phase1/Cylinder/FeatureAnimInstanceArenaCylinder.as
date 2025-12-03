UCLASS(Abstract)
class UFeatureAnimInstanceCylinder : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureCylinder Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureCylinderAnimData AnimData;

	// Add Custom Variables Here


	// The fraction of the time of each move the arena makes. Using this 0-1 float in the ABP to then multiply by the sequence length of each corresponding animation, the animation only progresses from start (0) to completed (1) with this value
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PlatformMoveTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int PlatformMoveIndex;

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
		ULocomotionFeatureCylinder NewFeature = GetFeatureAsClass(ULocomotionFeatureCylinder);
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

		PlatformMoveTimer = Rader.PlatformMoveAlpha;
		PlatformMoveIndex = Rader.PlatformMoveIndex;
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
