
namespace Behaviour
{
	bool IsChargeHit(AHazeActor Attacker, AHazeActor Target, float Radius, bool bCanEverHit = true, float PredictionTime = 0.1, float MinSpeed = 100.0)
	{
		if (!bCanEverHit)
			return false;

		FVector Vel = Attacker.GetActorVelocity();
		if (Vel.IsNearlyZero(MinSpeed))
			return false; // Too slow to hurt

		// Project target location on our predicted movement to see if we'll be passing target soon.
		FVector ProjectedTargetLocation;
		float ProjectedFraction = 1.0;
		FVector OwnLocation = Attacker.GetActorCenterLocation();
	#if EDITOR
		//Attacker.bHazeEditorOnlyDebugBool = true;
		if (Attacker.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugCapsule(OwnLocation + Vel * PredictionTime * 0.5, Radius + Vel.Size() * PredictionTime * 0.5, Radius, FRotator(90,0,0).Compose(Attacker.ActorForwardVector.Rotation()), FLinearColor::Red);
	#endif
		if (!Math::ProjectPositionOnLineSegment(OwnLocation, OwnLocation + Vel * PredictionTime, Target.ActorCenterLocation, ProjectedTargetLocation, ProjectedFraction))
		{
			if (ProjectedFraction == 0.0)
				return false; // We've passed target
		}

		if (ProjectedTargetLocation.DistSquared(Target.ActorCenterLocation) > Math::Square(Radius))
			return false; // Passing target, but too far away

		// Close enough to hit target!
		return true;
	}
}

