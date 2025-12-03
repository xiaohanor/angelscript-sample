class ASanctuaryForceZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;

	UPROPERTY(EditAnywhere)
	float ForceScale = 10.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseShape(FHazeTraceShape::MakeFromComponent(Collision));
		FOverlapResultArray OverlapResultArray = Trace.QueryOverlaps(Collision.WorldLocation);

		for (auto OverlapResult : OverlapResultArray.OverlapResults)
		{
			auto FauxPhysicsComponent = UFauxPhysicsComponentBase::Get(OverlapResult.Actor);

			if (FauxPhysicsComponent != nullptr)
			{
				FVector Force = Collision.WorldLocation - FauxPhysicsComponent.WorldLocation;

				FauxPhysicsComponent.ApplyForce(FauxPhysicsComponent.WorldLocation, Force * ForceScale);
			}
		}		
	}
}