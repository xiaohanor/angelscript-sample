UCLASS(Abstract)
class UFeatureAnimInstanceFlyingCarGunnerRifle : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFlyingCarGunnerRifle Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFlyingCarGunnerRifleAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AimSpaceX;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AimSpaceY;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAimingDownSights = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	USkylineFlyingCarGunnerComponent GunnerComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bReloading;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSitDown;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipSitEnter;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFlyingCarGunnerRifle NewFeature = GetFeatureAsClass(ULocomotionFeatureFlyingCarGunnerRifle);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Player);
		if (GunnerComponent != nullptr)
			bSkipSitEnter = GunnerComponent.IsSittingInsideCar();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (GunnerComponent == nullptr)
			return;

		bAimingDownSights = GunnerComponent.bIsInAimDown;
		bReloading = GunnerComponent.IsReloadingRifle() && AnimData.Reload.Sequence != nullptr;
		bSitDown = GunnerComponent.IsSittingInsideCar();

		if (bSitDown || TopLevelGraphRelevantStateName == n"SitExit")
		{
			AimSpaceX = 0;
			AimSpaceY = 0;
		}
		else
			GunnerComponent.GetAimSpaceData(AimSpaceX, AimSpaceY);
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

	UFUNCTION()
	void UAnimNotify_LeftAim()
	{
		bSkipSitEnter = false;
	}
}
