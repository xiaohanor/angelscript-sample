UCLASS(Abstract)
class UFeatureAnimInstanceIslandSkydive : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureIslandSkydive Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D Input;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int BarrelRollDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int HitReactionDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSlowMovement = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BarrelRollDuration;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureIslandSkydiveAnimData AnimData;

	UIslandEntranceSkydiveComponent SkydiveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureIslandSkydive NewFeature = GetFeatureAsClass(ULocomotionFeatureIslandSkydive);
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

		Input = SkydiveComp.AnimData.SkydiveInput;
	
		BarrelRollDuration = SkydiveComp.Settings.BarrelRollAnimationDuration;
		BarrelRollDirection = SkydiveComp.AnimData.BarrelRollDirection;

		HitReactionDirection = SkydiveComp.AnimData.HitReactionDirection;
		bSlowMovement = SkydiveComp.IsSlowMovementEnabled();
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const

	{
		//if (PrevLocomotionAnimationTag == n"IslandSkydive")
		//return 0.8;
	//else
		return 0.2;
	}
	

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
