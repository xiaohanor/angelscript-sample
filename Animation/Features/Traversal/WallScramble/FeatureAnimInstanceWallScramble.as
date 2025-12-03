
UCLASS(Abstract)
class UFeatureAnimInstanceWallScramble : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWallScramble Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWallScrambleAnimData AnimData;

	// Add Custom Variables Here


	UPROPERTY()
	UPlayerWallScrambleComponent WallScrambleComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerWallScrambleAnimData WallScrambleAnimData;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWallScramble NewFeature = GetFeatureAsClass(ULocomotionFeatureWallScramble);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		WallScrambleComp = UPlayerWallScrambleComponent::GetOrCreate(Player);

		// Implement Custom Stuff Here
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

		WallScrambleAnimData = WallScrambleComp.AnimData;
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
