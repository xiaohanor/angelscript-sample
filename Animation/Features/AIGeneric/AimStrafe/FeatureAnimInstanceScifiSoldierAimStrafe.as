UCLASS(Abstract)
class UFeatureAnimInstanceScifiSoldier_AimStrafe : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureScifiSoldier_AimStrafe Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureScifiSoldier_AimStrafeAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureScifiSoldier_AimStrafe NewFeature = GetFeatureAsClass(ULocomotionFeatureScifiSoldier_AimStrafe);
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
		Super::BlueprintUpdateAnimation(DeltaTime);
		if (Feature == nullptr)
			return;

		// Skyline enforcer spline entrance behaviour is only used by patrol enforcers no other behaviours can be active at the same time
		if (HazeOwningActor != nullptr && HazeOwningActor.IsAnyCapabilityActive(n"SkylineEnforcerSplineEntrance"))
		{
			bIsMoving = true;
			SpeedForward = 750.0; // This is hardcoded in spline entrance behaviour
		}
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
