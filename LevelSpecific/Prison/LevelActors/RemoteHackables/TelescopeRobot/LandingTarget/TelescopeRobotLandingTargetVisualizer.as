
class URemoteHackableTelescopeRobotLandingTargetVisualizerDummyComponent : UActorComponent { }

#if EDITOR
class URemoteHackableTelescopeRobotLandingTargetComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = URemoteHackableTelescopeRobotLandingTargetVisualizerDummyComponent;

	float ActiveDuration;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		if (Component.Owner == nullptr)
			return;

		ARemoteHackableTelescopeRobotLandingTarget LandingTarget = Cast<ARemoteHackableTelescopeRobotLandingTarget>(Component.Owner);
		if (LandingTarget == nullptr)
			return;

		float DeltaTime = Time::GetActorDeltaSeconds(LandingTarget);
		ActiveDuration += DeltaTime;

		// Eman TODO: Get proper dimensions once we get mesh
		float Radius = 70;
		float Alpha = (Math::Sin(ActiveDuration) + 1) * 0.5;

		FVector Start = LandingTarget.SplineTarget.WorldTransform.TransformPositionNoScale(LandingTarget.SplineTarget.SplinePoints[0].RelativeLocation) + FVector::UpVector * Radius;
		DrawSolidBox(n"TelescopeRobotLandingVisualizer1", Start, FQuat::Identity, FVector(Radius), FLinearColor::LucBlue, 0.5);

		FVector End = LandingTarget.SplineTarget.WorldTransform.TransformPositionNoScale(LandingTarget.SplineTarget.SplinePoints.Last().RelativeLocation) + FVector::UpVector * Radius;
		DrawSolidBox(n"TelescopeRobotLandingVisualizer2", End, FQuat::Identity, FVector(Radius), FLinearColor::LucBlue, 0.5);

		FVector Location = LandingTarget.SplineTarget.GetWorldLocationAtSplineFraction(Alpha) + FVector::UpVector * Radius;
		DrawSolidBox(n"TelescopeRobotLandingVisualizer3", Location, FQuat::Identity, FVector(Radius, Radius, Radius), FLinearColor::DPink, 0.2);


		// Visualize range
		DrawCircle(Start, LandingTarget.MaxRange, FLinearColor::Green + FLinearColor::Gray, 2, FVector::UpVector, 30);
		DrawCircle(End, LandingTarget.MaxRange, FLinearColor::Green + FLinearColor::Gray, 2, FVector::UpVector, 30);
	}
}
#endif