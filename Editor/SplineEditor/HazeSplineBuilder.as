struct FHazeSplineBuilderState
{
	UPROPERTY()
	FHazeSplineBuilderCircle Circle;
	UPROPERTY()
	FHazeSplineBuilderSpiral Spiral;
}

struct FHazeSplineBuilderCircle
{
	UPROPERTY()
	float Radius = 500.0;
	UPROPERTY()
	int PointCount = 10;
	UPROPERTY()
	float ArcDegrees = 360.0;
};

struct FHazeSplineBuilderSpiral
{
	UPROPERTY()
	float OuterRadius = 500;
	UPROPERTY()
	float InnerRadius = 1;
	UPROPERTY()
	int PointCount = 10;
	UPROPERTY()
	float ArcDegrees = 720.0;
	UPROPERTY()
	float Height = 0.0;
}