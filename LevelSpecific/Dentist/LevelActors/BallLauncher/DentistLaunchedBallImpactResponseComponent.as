event void FDentistLaunchedBallOnImpact(ADentistLaunchedBall LaunchedBall, FDentistLaunchedBallImpact Impact, bool bIsFirstImpact);

UCLASS(NotBlueprintable)
class UDentistLaunchedBallImpactResponseComponent : UActorComponent
{
	UPROPERTY()
	FDentistLaunchedBallOnImpact OnImpact;
};