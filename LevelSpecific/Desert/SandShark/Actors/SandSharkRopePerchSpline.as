/*
 * EXPERIMENTAL: A perch spline that will adjust itself to the positions of a AEnvironmentCable actor
 */
UCLASS(NotBlueprintable)
class ASandSharkRopePerchSpline : APerchSpline
{
	UPROPERTY(EditInstanceOnly)
	AEnvironmentCable RopeActor;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(RopeActor == nullptr)
			return;

		SetActorLocationAndRotation(RopeActor.ActorLocation, RopeActor.ActorQuat);
		AttachToActor(RopeActor);

		Spline.SplinePoints.Reset();

		for(int i = 0; i < RopeActor.Cable.Particles.Num(); i++)
		{
			FVector RelativeLocation = RopeActor.Cable.GetParticlePosition(i);
			FVector Location = ActorTransform.InverseTransformPosition(RelativeLocation);
			FHazeSplinePoint SplinePoint(Location);
			Spline.SplinePoints.Add(SplinePoint);
		}

		Spline.UpdateSpline();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(int i = 0; i < RopeActor.Cable.Particles.Num(); i++)
		{
			FVector WorldLocation = RopeActor.Cable.GetParticlePosition(i);
			FVector RelativeLocation = ActorTransform.InverseTransformPosition(WorldLocation);
			Spline.SplinePoints[i].RelativeLocation = RelativeLocation;
		}

		Spline.UpdateSpline();

		FEnvironmentShockwaveForceData ForceData;
		ForceData.Epicenter = ActorLocation + FVector(0, 100, -100);
		ForceData.Strength = Math::Sin(Time::GameTimeSeconds * 2) * 300;
		RopeActor.AddShockwaveForce(ForceData);
	}
};