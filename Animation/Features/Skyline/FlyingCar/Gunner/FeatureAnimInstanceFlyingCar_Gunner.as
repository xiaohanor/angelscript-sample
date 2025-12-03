UCLASS(Abstract)
class UFeatureAnimInstanceFlyingCar_Gunner : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFlyingCar_Gunner Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFlyingCar_GunnerAnimData AnimData;

	UPROPERTY(Transient, NotEditable)
	float AimSpaceX;

	UPROPERTY(Transient, NotEditable)
	float AimSpaceY;

	UPROPERTY(Transient, NotEditable)
	bool bReloading;

	UPROPERTY(Transient, NotEditable)
	bool bAimingDownSights;

	UPROPERTY(Transient, NotEditable)
	EFlyingCarGunnerState GunnerState;


	UPROPERTY(Transient, NotEditable)
	USkylineFlyingCarGunnerComponent GunnerComponent;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFlyingCar_Gunner NewFeature = GetFeatureAsClass(ULocomotionFeatureFlyingCar_Gunner);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (GunnerComponent == nullptr)
			return;

		GunnerState = GunnerComponent.GetGunnerState();

		Print("Blend space " + AimSpaceX, 0);
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
