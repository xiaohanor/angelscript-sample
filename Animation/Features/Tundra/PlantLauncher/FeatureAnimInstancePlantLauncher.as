UCLASS(Abstract)
class UFeatureAnimInstancePlantLauncher : UHazeAnimInstanceBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeaturePlantLauncher Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePlantLauncherAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Weight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunched;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ELaunchPadWeightMode WeightMode = ELaunchPadWeightMode::None;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor == nullptr)
			return;

		AnimData = Feature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
			return;

		auto Data = Cast<ATundraCrackLaunchpad>(HazeOwningActor).AnimData;
		Weight = Data.Weight;
		bIsLaunched = Data.bIsLaunched;
		WeightMode = Data.WeightMode;
	}
}
