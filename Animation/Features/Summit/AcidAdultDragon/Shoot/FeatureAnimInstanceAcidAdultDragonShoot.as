UCLASS(Abstract)
class UFeatureAnimInstanceAcidAdultDragonShoot : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAcidAdultDragonShoot Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAcidAdultDragonShootAnimData AnimData;

	UAdultDragonAcidChargeProjectileComponent ShootComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ChargeFloat;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShoot;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		ShootComp = UAdultDragonAcidChargeProjectileComponent::Get(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureAcidAdultDragonShoot NewFeature = GetFeatureAsClass(ULocomotionFeatureAcidAdultDragonShoot);
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
		
		ChargeFloat = ShootComp.ChargeAnimationParams.ChargeAlpha;
		bShoot = ShootComp.ChargeAnimationParams.bShootSuccess;
		Print("bShoot: " + bShoot, 0.f);

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (TopLevelGraphRelevantStateName == n"Charge")
		{
			return true;
		}

		return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTimeWhenResetting() const
	{
		return 0.5;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.5;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
