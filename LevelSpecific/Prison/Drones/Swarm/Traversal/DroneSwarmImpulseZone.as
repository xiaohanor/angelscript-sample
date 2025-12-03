class ADroneSwarmImpulseZone : ADroneSwarmMoveZone
{
	UPROPERTY(DefaultComponent)
	SwarmDrone::USwarmDroneImpulseZoneDummyVisualizationComponent DummyVisualizer;

	UPROPERTY(EditInstanceOnly)
	float Impulse = 3000.0;

	FVector CalculateAccelerationAtLocation(FVector WorldLocation) const override
	{
		return GetMoveDirection() * Impulse;
	}
}

namespace SwarmDrone
{
	class USwarmDroneImpulseZoneDummyVisualizationComponent : UActorComponent { }
	class USwarmDroneImpulseZoneComponentVisualizer : UHazeScriptComponentVisualizer
	{
		default VisualizedClass = USwarmDroneImpulseZoneDummyVisualizationComponent;

		UFUNCTION(BlueprintOverride)
		void VisualizeComponent(const UActorComponent Component)
		{
			ADroneSwarmImpulseZone ImpulseZone = Cast<ADroneSwarmImpulseZone>(Component.Owner);
			if (ImpulseZone == nullptr)
				return;

			FHitResult HitResult;
			TArray<FVector> PathLocations;
			FVector LastTracedDestination;
			TArray<AActor> IgnoredActors;
			FVector LaunchVelocity = ImpulseZone.GetMoveDirection() * ImpulseZone.Impulse;

			// TODO: Replace this with individual traces since Gameplay:: is now hidden
			//Gameplay::Blueprint_PredictProjectilePath_ByTraceChannel(HitResult, PathLocations, LastTracedDestination, ImpulseZone.ActorLocation, LaunchVelocity, false, 10, ECollisionChannel::PlayerCharacter, false, IgnoredActors, EDrawDebugTrace::None, 0, 15, 4, -Drone::Gravity);

			for (int i = 0; i < PathLocations.Num() - 1; i++)
			{
				DrawDashedLine(PathLocations[i], PathLocations[i + 1], FLinearColor::DPink, 10, 5);
			}
		}
	}
}