
UCLASS(Abstract)
class UFeatureAnimInstanceGravityGrenade : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGravityGrenade Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGravityGrenadeAnimData AnimData;

	UPROPERTY()
	bool bUsingRightArm;

	UPROPERTY()
	float ThrowAngle;

	UPROPERTY()
	UScifiPlayerGravityGrenadeManagerComponent Component;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGravityGrenade NewFeature = GetFeatureAsClass(ULocomotionFeatureGravityGrenade);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
			Component = UScifiPlayerGravityGrenadeManagerComponent::Get(Player);
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bUsingRightArm = true;
		FVector ThrowDirection = Component.GetLastThrownDirection();
		FVector ForwardVector = Component.Owner.ActorForwardVector;
		ThrowAngle = ThrowDirection.GetAngleDegreesTo(ForwardVector);
		ThrowAngle *= Math::Sign(ThrowDirection.DotProduct(Component.Owner.ActorRightVector));
		PrintToScreen("ThrowAngle " + ThrowAngle);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		const float TimeRemaining = GetTopLevelGraphRelevantAnimTimeRemaining();
		if (TimeRemaining <= KINDA_SMALL_NUMBER)
		{
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
