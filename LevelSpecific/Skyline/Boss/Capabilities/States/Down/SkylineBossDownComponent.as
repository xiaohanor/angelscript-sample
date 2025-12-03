UCLASS(NotBlueprintable, HideCategories = "Debug ComponentTick Activation Cooking Disable Tags Navigation")
class USkylineBossDownComponent : UActorComponent
{
	access Hatch = private, USkylineBossOpenHatchCapability, USkylineBossCloseHatchCapability;
	access Core = private, USkylineBossExposeCoreCapability;

	private ASkylineBoss Boss;

	bool bShouldRise = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ASkylineBoss>(Owner);
	}

	void Reset()
	{
		bShouldRise = false;
	}
};