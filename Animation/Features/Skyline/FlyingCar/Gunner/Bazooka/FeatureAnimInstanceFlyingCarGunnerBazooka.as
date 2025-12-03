UCLASS(Abstract)
class UFeatureAnimInstanceFlyingCarGunnerBazooka : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFlyingCarGunnerBazooka Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFlyingCarGunnerBazookaAnimData AnimData;


	UPROPERTY(Transient, NotEditable)
	float AimSpaceX;

	UPROPERTY(Transient, NotEditable)
	float AimSpaceY;

	UPROPERTY(Transient, NotEditable)
	bool bAimingDownSights = false;


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
		ULocomotionFeatureFlyingCarGunnerBazooka NewFeature = GetFeatureAsClass(ULocomotionFeatureFlyingCarGunnerBazooka);
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

		GunnerComponent.GetAimSpaceData(AimSpaceX, AimSpaceY);

		bAimingDownSights = GunnerComponent.bIsInAimDown;
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
