class ASkylineMallChaseSpline : ASplineActor
{
};

#if EDITOR
class USkylineMallChaseSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(ASkylineMallChaseSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Skyline Mall Chase Spline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		{
			FHazeContextOption AddComponent;
			AddComponent.DelegateParam = n"AddComponent";
			AddComponent.Label = "Add Component";
			AddComponent.Icon = n"Icons.Plus";
			AddComponent.Tooltip = "Cool tooltip text";
			Menu.AddOption(AddComponent, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddComponent")
		{
			auto AddedComp = USkylineMallChaseAlongSplineComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedComp.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedComp);
			Spline.Owner.Modify();
		}
	}
};
#endif