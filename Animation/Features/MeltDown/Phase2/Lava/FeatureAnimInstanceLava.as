UCLASS(Abstract)
class UFeatureAnimInstanceLava : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureLava Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureLavaAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttackLeft = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttackRight = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttackDown = false;


	// Add Custom Variables Here

	AMeltdownBossPhaseTwo Rader;
	
	//Rader is alternating between tracking the two different players and trying to hit them. The coordinates on the arena correspond to values in the blendspace. -1 is the furthest to the left (in screenspace, looking at Rader), 0 is mid, and 1 is to the right in screenspace.
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float OverHeadSwingBSValues;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

		Rader = Cast<AMeltdownBossPhaseTwo>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureLava NewFeature = GetFeatureAsClass(ULocomotionFeatureLava);
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

		bAttackLeft = Rader.LastLeftAttackFrame >= GFrameNumber-1;
		bAttackRight = Rader.LastRightAttackFrame >= GFrameNumber-1;
		bAttackDown = Rader.LastDownAttackFrame >= GFrameNumber-1;
		OverHeadSwingBSValues = Rader.TelegraphAttackPosition;
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
