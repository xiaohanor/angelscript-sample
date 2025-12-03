UCLASS(NotBlueprintable, HideCategories = "CameraOptions Camera PostProcess Debug Activation Cooking Tags Collision Rendering LOD")
class UGravityBikeSplineCameraLookComponent : UCameraComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditInstanceOnly)
	bool bOverrideIdealDistance = false;

	UPROPERTY(EditInstanceOnly)
	float IdealDistance = 500;

	// FOV is set on the Camera Settings
	UPROPERTY(EditInstanceOnly)
	bool bOverrideFOV = false;
	default FieldOfView = GravityBikeSpline::DefaultFOV;

	UPROPERTY(VisibleInstanceOnly)
	float DistanceAlongSpline;

	private UHazeSplineComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		SplineComp = Spline::GetGameplaySpline(Owner);

		if(!ensure(HasValidSpline()))
			return;

		DistanceAlongSpline = SplineComp.GetClosestSplineDistanceToWorldLocation(WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}

	bool HasValidSpline() const
	{
		auto Spline = SplineComp;

		if(Spline == nullptr)
			Spline = Spline::GetGameplaySpline(Owner);
		
		if(Spline == nullptr)
			return false;

		if(Spline.SplinePoints.Num() < 2)
			return false;

		if(Spline.SplineLength < 1)
			return false;

		return true;
	}

	int opCmp(UGravityBikeSplineCameraLookComponent Other) const
	{
		if(DistanceAlongSpline > Other.DistanceAlongSpline)
			return 1;
		else
			return -1;
	}
};

class UGravityBikeSplineCameraLookComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineCameraLookComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const auto LookComp = Cast<UGravityBikeSplineCameraLookComponent>(Component);
		if(LookComp == nullptr)
			return;

		auto CameraLookSplineComp = UGravityBikeSplineCameraLookSplineComponent::Get(LookComp.Owner);
		if(CameraLookSplineComp == nullptr)
			return;

		const auto SplineComp = UHazeSplineComponent::Get(LookComp.Owner);
		if(SplineComp == nullptr)
			return;

		CameraLookSplineComp.Initialize();

		const float Interval = 5000;
		float Distance = 0;
		float DistanceOffset = Time::GameTimeSeconds * 2000;
		while(Distance < SplineComp.SplineLength)
		{
			float TestDistance = (Distance + DistanceOffset) % SplineComp.SplineLength;
			FTransform Transform = SplineComp.GetWorldTransformAtSplineDistance(TestDistance);
			FVector Location = Transform.Location + Transform.Rotation.UpVector * 500;
			FQuat Rotation = CameraLookSplineComp.GetCameraRotationAtDistanceAlongSpline(TestDistance, 0);
			DrawCoordinateSystem(Location, Rotation.Rotator(), 500, 50);
			Distance += Interval;
		}
	}
}