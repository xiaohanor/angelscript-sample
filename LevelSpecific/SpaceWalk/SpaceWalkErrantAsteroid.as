class ASpaceWalkErrantAsteroid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsSplineFollowComponent AsteroidSpline;

	UPROPERTY(DefaultComponent, Attach = AsteroidSpline)
	UStaticMeshComponent Asteroid;

	UPROPERTY(DefaultComponent, Attach = Asteroid)
	UFauxPhysicsForceComponent AsteroidForce;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}
};