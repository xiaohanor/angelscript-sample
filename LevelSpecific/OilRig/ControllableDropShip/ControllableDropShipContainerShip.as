UCLASS(Abstract)
class AControllableDropShipContainerShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShipRoot;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FlySpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor PlayerSpline;

	UPROPERTY(EditAnywhere)
	bool bPreviewEnd = false;

	bool bFlying = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEnd)
			ShipRoot.SetWorldLocation(FlySpline.Spline.GetWorldLocationAtSplineFraction(1.0));
		else
			ShipRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION()
	void StartFlying()
	{
		bFlying = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bFlying)
		{
			float PlayerSplineFraction = PlayerSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation)/PlayerSpline.Spline.SplineLength;
			PrintToScreen("" + PlayerSplineFraction);

			FVector Loc = FlySpline.Spline.GetWorldLocationAtSplineFraction(PlayerSplineFraction);
			SetActorLocation(Loc);
		}
	}
}