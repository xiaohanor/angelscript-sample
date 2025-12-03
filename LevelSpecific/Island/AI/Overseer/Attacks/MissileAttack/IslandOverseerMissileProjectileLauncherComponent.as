class UIslandOverseerMissileProjectileLauncherComponent : UBasicAIProjectileLauncherComponent
{
	private TArray<USceneComponent> LaunchPoints;
	private int LaunchIndex;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		TArray<USceneComponent> LeftPoints;
		TArray<USceneComponent> RightPoints;
		UIslandOverseerLeftLaunchPointContainerComponent::Get(Owner).GetChildrenComponents(false, LeftPoints);
		UIslandOverseerRightLaunchPointContainerComponent::Get(Owner).GetChildrenComponents(false, RightPoints);
		
		for(USceneComponent Point : LeftPoints)
			LaunchPoints.Add(Point);

		for(USceneComponent Point : RightPoints)
			LaunchPoints.Add(Point);

		LaunchPoints.Shuffle();
	}

	FVector GetNextLaunchLocation()
	{
		if(LaunchPoints.Num() == 0)
			return WorldTransform.TransformPosition(LaunchOffset);

		FVector Location = LaunchPoints[LaunchIndex].WorldLocation;
		LaunchIndex++;
		if(LaunchIndex >= LaunchPoints.Num())
			LaunchIndex = 0;
		return Location;
	}
}