UCLASS(Abstract)
class AVineGrowerr : AHazeActor
{
	UPROPERTY(EditInstanceOnly)
	APropLine PropLine;

	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = Spline::GetGameplaySpline(PropLine);
	}
}