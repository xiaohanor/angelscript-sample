class ASkylineWaterWorldPoolVolume : AVolume
{
	default BrushComponent.LineThickness = 2.0;
    default Shape::SetVolumeBrushColor(this, ColorDebug::Cyan);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};