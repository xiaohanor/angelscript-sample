UCLASS(Abstract)
class UFeatureAnimInstanceDroneHang : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDroneHang Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDroneHangAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SidewaysTiltInput;

	UIslandDroidZiplinePlayerComponent DroidZiplineComp;
	

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
	DroidZiplineComp = UIslandDroidZiplinePlayerComponent::Get (Player);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDroneHang NewFeature = GetFeatureAsClass(ULocomotionFeatureDroneHang);
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

		SidewaysTiltInput = DroidZiplineComp.AnimData.SidewaysTiltInput;
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
