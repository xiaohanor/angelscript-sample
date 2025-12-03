event void FTrailTesterTick(float DeltaTime);

class ATrailTester : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent,ShowOnActor)
	UTrailTesterComponent TrailTesterMovementComponent;
}

class UTrailTesterComponent : USceneComponent
{
	default bTickInEditor = true;

	UPROPERTY(EditAnywhere, Category = "Tester Params")
	float Speed = 5;

	UPROPERTY(EditAnywhere, Category = "Tester Params")
	float Radius = 100;

	FVector StartLocation = FVector::ZeroVector;
	FVector DesiredDeltaFromStartLocation = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		StartLocation = GetWorldLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MoveComponent(DeltaSeconds);
	}

	void MoveComponent(const float Dt)
	{
		const float Theta = Time::GetGameTimeSeconds() * Speed;
		const FVector DeltaFromStartLocation = FVector(Math::Cos(Theta), Math::Sin(Theta), 0) * Radius;
		const FVector NewLocation = Owner.GetActorLocation() + DeltaFromStartLocation;
		SetWorldLocation(NewLocation);

		// Debug::DrawDebugPoint(StartLocation, 150, FLinearColor::Yellow);
		// Debug::DrawDebugPoint(NewLocation, 20, FLinearColor::Green, Duration =  2);
	}

}