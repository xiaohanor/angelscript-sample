UCLASS(Abstract)
class AGarbageBot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BotRoot;

	UPROPERTY(DefaultComponent, Attach = BotRoot)
	USceneComponent PropellerRoot;

	UPROPERTY(DefaultComponent, Attach = BotRoot)
	USceneComponent ClawRoot1;

	UPROPERTY(DefaultComponent, Attach = BotRoot)
	USceneComponent ClawRoot2;

	UPROPERTY(DefaultComponent, Attach = BotRoot)
	USceneComponent ClawRoot3;

	UPROPERTY(DefaultComponent, Attach = BotRoot)
	USceneComponent ClawRoot4;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditInstanceOnly)
	ASplineActor Spline;
	float SplineDist = 0.0;
	float SplineSpeed = 400.0;

	UPROPERTY(EditAnywhere)
	bool bWiggleClaws = true;

	float PropellerRotRate = 1000.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PropellerRoot.AddLocalRotation(FRotator(0.0, PropellerRotRate * DeltaTime, 0.0));

		if (Spline != nullptr)
		{
			SplineDist += SplineSpeed * DeltaTime;
			SetActorLocation(Spline.Spline.GetWorldLocationAtSplineDistance(SplineDist));
			if (SplineDist >= Spline.Spline.SplineLength)
				SplineDist = 0.0;
		}
	}
}