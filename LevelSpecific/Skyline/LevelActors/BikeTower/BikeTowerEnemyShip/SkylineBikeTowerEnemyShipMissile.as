class ASkylineBikeTowerEnemyShipMissile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USkylineSplineMissileComponent SplineMissileComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	FTransform TargetTransform;
	USceneComponent TargetComponent;
	float TimeToImpact = 0.0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Curve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TargetComponent != nullptr)
			SplineMissileComp.Launch(TargetComponent);
		else
			SplineMissileComp.Launch(TargetTransform);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = GameTimeSinceCreation / TimeToImpact;

		if (TargetComponent != nullptr)
			SplineMissileComp.UpdateSpline();

		SplineMissileComp.SetDistanceAlpha(Curve.GetFloatValue(Alpha));
	}
};