UCLASS(Abstract)
class UFeatureAnimInstanceMeltdownBossFlying : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureMeltdownBossFlying Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureMeltdownBossFlyingAnimData AnimData;

	UPROPERTY()
	FVector2D FlyingBlendSpace;
	UPROPERTY()
	FVector2D DashingBlendSpace;
	UPROPERTY()
	bool bIsDashing;

	UMeltdownBossFlyingComponent MeltdownFlightComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureMeltdownBossFlying NewFeature = GetFeatureAsClass(ULocomotionFeatureMeltdownBossFlying);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MeltdownFlightComp = UMeltdownBossFlyingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		FlyingBlendSpace = MeltdownFlightComp.MovementBlendSpaceValue;
		DashingBlendSpace = MeltdownFlightComp.DashDirection;
		bIsDashing = MeltdownFlightComp.bIsDashing;
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
