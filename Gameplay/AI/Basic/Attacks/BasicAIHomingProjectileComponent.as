class UBasicAIHomingProjectileComponent : UActorComponent
{
	AHazeActor Target;
	FVector GetPlanarHomingAcceleration(FVector TargetLocation, FVector PlaneNormal, float HomingStrength)
	{
		if (Target == nullptr)
			return FVector::ZeroVector;

		FVector ToTarget = (TargetLocation - Owner.ActorLocation);
		FVector	PerpendicularToTarget = ToTarget.VectorPlaneProject(PlaneNormal);
		return PerpendicularToTarget * HomingStrength;
	}
}
