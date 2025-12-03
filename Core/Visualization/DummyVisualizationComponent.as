struct FDummyVisualizationSphere
{
	USceneComponent CenterComp;
	float Radius;
	float Thickness;
	int Segments;

	FDummyVisualizationSphere(USceneComponent CenterComponent, float InRadius, float InThickness = 1.0, int InSegments = 12)
	{
		this.CenterComp = CenterComponent;
		this.Radius = InRadius;
		this.Thickness = InThickness;
		this.Segments = InSegments;
	}
}

struct FDummyVisualizationCylinder
{
	USceneComponent CenterComp;
	float Radius;
	float HalfHeight;
	FVector Offset; 
	float Thickness;
	int Segments;

	FDummyVisualizationCylinder(USceneComponent CenterComponent, float InRadius, float InBottomHeight, float InTopHeight, float InThickness = 1.0, int InSegments = 12)
	{
		this.CenterComp = CenterComponent;
		this.Radius = InRadius;
		this.Thickness = InThickness;
		this.Segments = InSegments;
		this.HalfHeight = (InTopHeight - InBottomHeight) * 0.5;
		this.Offset = FVector(0.0, 0.0, InTopHeight - HalfHeight);
	}
}


class UDummyVisualizationComponent : UActorComponent
{
	// Note that the user will need to update appropriate values in construction script
	TArray<AActor> ConnectedActors;
	TArray<FVector> ConnectedLocalLocations;
	float DashSize = 20.0;
	float Thickness = 3.0;
	FLinearColor Color = FLinearColor::White;

	USceneComponent ConnectionBase = nullptr;
	FVector ConnectionBaseOffset = FVector::ZeroVector;

	TArray<FDummyVisualizationSphere> Spheres;
	TArray<FDummyVisualizationCylinder> Cylinders;
}
