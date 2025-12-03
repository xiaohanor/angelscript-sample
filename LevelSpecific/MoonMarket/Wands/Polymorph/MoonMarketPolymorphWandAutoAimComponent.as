class UMoonMarketPolymorphAutoAimComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"MoonMarketPolymorph";
	default AutoAimMaxAngle = 4;
	default MaximumDistance = 1500;

	FVector OriginalRelativeLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OriginalRelativeLocation = RelativeLocation;
		if(Cast<AHazePlayerCharacter>(Owner) != nullptr)
			DisableForPlayer(Cast<AHazePlayerCharacter>(Owner), this);
	}
};