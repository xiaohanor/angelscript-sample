struct FSummitDarkCaveBouncyPersimmonOnLandedParams
{
	UPROPERTY()
	FVector LandLocation;
}

struct FSummitDarkCaveBouncyPersimmonOnLaunchedParams
{
	UPROPERTY()
	AHazePlayerCharacter LaunchedPlayer;

	UPROPERTY()
	FVector LaunchVelocity;
}

UCLASS(Abstract)
class USummitDarkCaveBouncyPersimmonEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLandedOnPersimmon(FSummitDarkCaveBouncyPersimmonOnLandedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchedPlayer(FSummitDarkCaveBouncyPersimmonOnLaunchedParams Params)
	{
	}
};