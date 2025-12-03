
UCLASS(Abstract)
class UFeatureAnimInstanceShieldBuster : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureShieldBuster Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureShieldBusterAnimData AnimData;

	UPROPERTY()
	bool bUsingRightArm;

	UPROPERTY()
	float ThrowAngle;

	UPROPERTY()
	UScifiPlayerShieldBusterManagerComponent Component;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureShieldBuster NewFeature = GetFeatureAsClass(ULocomotionFeatureShieldBuster);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
			Component = UScifiPlayerShieldBusterManagerComponent::Get(Player);
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bUsingRightArm = Component.LastThrowHand == EScifiPlayerShieldBusterHand::Right;
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
