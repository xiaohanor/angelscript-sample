class UFairyPerchSplineRestManagerComponent : UActorComponent
{
	TArray<UFairyPerchSplineRestComponent> SortedRestComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(UFairyPerchSplineRestComponent, SortedRestComponents);
		SortedRestComponents.Sort();
	}

	int GetValidRestDirection(float SplineDistance) const
	{
		for(int i = 0; i < SortedRestComponents.Num(); i++)
		{
			auto RestComp = SortedRestComponents[i];
			if(SplineDistance > RestComp.DistanceAlongSpline)
				continue;

			if(i == 0)
				break;

			if(IsStartComponent(i - 1))
			{
				auto PreviousRestComp = SortedRestComponents[i - 1];
				return PreviousRestComp.bRightFacing ? 1 : -1;
			}

			break;
		}

		return 0;
	}

	bool IsStartComponent(int Index) const
	{
		return Index % 2 == 0;
	}
}

class UFairyPerchSplineRestComponent : UAlongSplineComponent
{
	UPROPERTY(EditInstanceOnly)
	bool bRightFacing = true;

	private TOptional<float> Internal_DistanceAlongSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Internal_DistanceAlongSpline = CalculateDistanceAlongSpline();
		UFairyPerchSplineRestManagerComponent::GetOrCreate(Owner);
	}

	int opCmp(UFairyPerchSplineRestComponent Other) const
	{
		return DistanceAlongSpline > Other.DistanceAlongSpline ? 1 : -1;
	}

	float GetDistanceAlongSpline() const property
	{
		if(Internal_DistanceAlongSpline.IsSet())
			return Internal_DistanceAlongSpline.Value;

		return CalculateDistanceAlongSpline();
	}

	float CalculateDistanceAlongSpline() const
	{
		UHazeSplineComponent Spline = Spline::GetGameplaySpline(Owner);
		return Spline.GetClosestSplineDistanceToWorldLocation(WorldLocation);
	}

	void GetSortedRestComponents(TArray<UFairyPerchSplineRestComponent>&out OutSortedRestComponents, int&out OurIndex)
	{
		GetSortedRestComponents(OutSortedRestComponents);
		OurIndex = OutSortedRestComponents.FindIndex(this);
	}

	void GetSortedRestComponents(TArray<UFairyPerchSplineRestComponent>&out OutSortedRestComponents)
	{
		OutSortedRestComponents.Reset();
		Owner.GetComponentsByClass(UFairyPerchSplineRestComponent, OutSortedRestComponents);
		OutSortedRestComponents.Sort();
	}
}

#if EDITOR
class UFairyPerchSplineRestDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = UFairyPerchSplineRestComponent;

	TArray<UFairyPerchSplineRestComponent> SortedRestComponents;
	int OurIndex;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		auto RestComp = Cast<UFairyPerchSplineRestComponent>(GetCustomizedObject());
		RestComp.GetSortedRestComponents(SortedRestComponents, OurIndex);
		
		if(!IsStartComponent())
			HideProperty(n"bRightFacing");
	}

	bool IsStartComponent() const
	{
		return OurIndex % 2 == 0;
	}
}

class UFairyPerchSplineRestVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UFairyPerchSplineRestComponent;

	TArray<UFairyPerchSplineRestComponent> SortedRestComponents;
	int OurIndex;

	UFairyPerchSplineRestComponent RestComp;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		RestComp = Cast<UFairyPerchSplineRestComponent>(Component);
		RestComp.GetSortedRestComponents(SortedRestComponents, OurIndex);
		Super::VisualizeComponent(Component);
		
		if(!IsStartComponent())
			return;

		if(SortedRestComponents.Num() - 1 == OurIndex)
			return;

		UFairyPerchSplineRestComponent NextComp = SortedRestComponents[OurIndex + 1];
		DrawLine(RestComp.WorldLocation, NextComp.WorldLocation, FLinearColor::Green, 2.0);

		float Sign = RestComp.bRightFacing ? 1.0 : -1.0;
		DrawArrow(RestComp.WorldLocation, RestComp.WorldLocation + RestComp.RightVector * 40.0 * Sign, FLinearColor::Green, 5.0, 2.0);
		DrawArrow(NextComp.WorldLocation, NextComp.WorldLocation + NextComp.RightVector * 40.0 * Sign, FLinearColor::Green, 5.0, 2.0);
	}

	void DrawSelectedShape(UAlongSplineComponent AlongSplineComp, FLinearColor SelectedColor) const override
	{
		DrawPoint(RestComp.WorldLocation, Color, 40);
	}

	void DrawDeselectedShape(UAlongSplineComponent AlongSplineComp, FLinearColor DeselectedColor) const override
	{
		DrawPoint(RestComp.WorldLocation, Color, 40);
	}

	FLinearColor GetColor() const property
	{
		if(IsStartComponent())
			return FLinearColor::Green;

		return FLinearColor::Red;
	}

	bool IsStartComponent() const
	{
		return OurIndex % 2 == 0;
	}
}
#endif