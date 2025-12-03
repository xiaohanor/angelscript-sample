UCLASS(Abstract)
class UFeatureAnimInstanceWaterCannon : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWaterCannon Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWaterCannonAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsShooting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	AInnerCityWaterCannon WaterCannon;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator PitchRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		WaterCannon = Cast<AInnerCityWaterCannon>(Player.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWaterCannon NewFeature = GetFeatureAsClass(ULocomotionFeatureWaterCannon);
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
		if (WaterCannon == nullptr)
			return;

		bIsShooting = WaterCannon.bIsShootingWater;

		PitchRotation.Pitch = -WaterCannon.TurretPitchRoot.WorldRotation.Pitch;

		BlendspaceValues = FVector2D(
			-WaterCannon.YawForceComp.Force.X / 200,
			1 - (WaterCannon.TurretPitchRoot.RelativeRotation.Pitch + 20) / 40);
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
