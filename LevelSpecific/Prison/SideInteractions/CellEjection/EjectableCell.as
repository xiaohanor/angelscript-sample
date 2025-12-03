class AEjectableCell : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CellRoot;

	UPROPERTY(EditInstanceOnly)
	ASplineActor EjectSpline;

	float EjectSpeed = 0.0;
	FSplinePosition SplinePos;
	bool bEjecting = false;

	UFUNCTION()
	void Eject()
	{
		SplinePos = FSplinePosition(EjectSpline.Spline, 0.0, true);
		bEjecting = true;
		SetActorTickEnabled(true);

		UEjectableCellEffectEventHandler::Trigger_Eject(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		EjectSpeed += 40.0 * DeltaTime;
		SplinePos.Move(EjectSpeed);

		SetActorLocation(SplinePos.WorldLocation);
		if (SplinePos.IsAtEnd())
			AddActorDisable(this);
	}
}

class UEjectableCellEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Eject() {}
	 
}