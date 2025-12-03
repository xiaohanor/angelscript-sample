struct FActiveAutoRun
{
	UHazeSplineComponent Spline;
	FVector StaticDirection;
	FPlayerAutoRunSettings Settings;
};

UCLASS(NotPlaceable, NotBlueprintable)
class UPlayerAutoRunComponent : UActorComponent
{
	TInstigated<FActiveAutoRun> ActiveAutoRun;
};