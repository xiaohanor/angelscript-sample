class ASkylineMallChaseEnemyShipProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USkylineSplineMissileComponent SplineMissileComp;

	FTransform Target;
	float TimeToImpact = 0.0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Curve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineMissileComp.Launch(Target);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = GameTimeSinceCreation / TimeToImpact;
		SplineMissileComp.SetDistanceAlpha(Curve.GetFloatValue(Alpha));
	}
};