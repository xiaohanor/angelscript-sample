UCLASS(Abstract)
class ACoastBossPlayerLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	/* This amount will be subtracted from the CoastBoss's collision sphere radius to make the beam stop closer to the coast boss. */
	UPROPERTY(EditDefaultsOnly)
	float DecreaseRadiusForLaserBeamEnd = 100.0;

	FVector BeamEnd;

	void SetBeamEnd(FVector Location)
	{
		BeamEnd = Location;
		BP_SetBeamEnd(Location);
	}

	UFUNCTION(BlueprintEvent)
	void BP_SetBeamEnd(FVector Location) {}

	bool bCurrentlyHittingCoastBoss = false;
}