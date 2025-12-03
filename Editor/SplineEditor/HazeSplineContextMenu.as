
namespace SplineContextMenu
{
	UHazeSplineContextMenu GetSingleton()
	{
		return Cast<UHazeSplineContextMenu>(UHazeSplineContextMenu.DefaultObject);
	}
}

class UHazeSplineContextMenu
{
	TSoftObjectPtr<UHazeSplineComponent> MenuSpline;
	UHazeSplineSelection MenuSelection;
	float MenuClickedDistance;
	int MenuClickedPoint;
	TArray<UHazeSplineContextMenuExtension> ValidExtensions;

	void GenerateContextMenu(FHazeContextMenu& Menu,
		UHazeSplineComponent Spline, UHazeSplineSelection Selection,
		int ClickedPoint = -1, float ClickedDistance = -1.0)
	{
		FHazeContextDelegate MenuDelegate(this, n"HandleContextOptionClicked");
		MenuSpline = Spline;
		MenuSelection = Selection;
		MenuClickedPoint = ClickedPoint;
		MenuClickedDistance = ClickedDistance;

		if (Spline.SplinePoints.IsValidIndex(ClickedPoint))
		{
			const FHazeSplinePoint& SplinePoint = Spline.SplinePoints[ClickedPoint];

			// A spline point was clicked
			Menu.BeginSection("Spline Point");

			FHazeContextOption OverrideTangents;
			OverrideTangents.Type = EHazeContextOptionType::Checkbox;
			OverrideTangents.Label = "Override Tangents";
			OverrideTangents.Tooltip = "Specify overridden tangents for this point instead of relying on the automatic ones.";
			OverrideTangents.bChecked = SplinePoint.bOverrideTangent;
			OverrideTangents.DelegateParam = n"OverrideTangent";
			Menu.AddOption(OverrideTangents, MenuDelegate);

			if (SplinePoint.bOverrideTangent)
			{
				FHazeContextOption DiscontinuousTangents;
				DiscontinuousTangents.Type = EHazeContextOptionType::Checkbox;
				DiscontinuousTangents.Label = "Discontinuous Tangents";
				DiscontinuousTangents.Tooltip = "Allow the arrive and leave tangents to be set to different values.";
				DiscontinuousTangents.bChecked = SplinePoint.bOverrideTangent;
				DiscontinuousTangents.DelegateParam = n"DiscontinuousTangent";
				Menu.AddOption(DiscontinuousTangents, MenuDelegate);
			}

			FHazeContextOption StraightTangents;
			StraightTangents.Label = "Calculate Straight Tangents";
			StraightTangents.Tooltip = "Set the tangents on the selected spline points to be straight based on the position of the other points";
			StraightTangents.DelegateParam = n"StraightTangents";
			Menu.AddOption(StraightTangents, MenuDelegate);

			Menu.EndSection();
		}
		else
		{
			if (ClickedDistance >= 0.0)
			{
				FHazeContextOption AddPoint;
				AddPoint.DelegateParam = n"AddPoint";
				AddPoint.Label = "Add Spline Point Here";
				AddPoint.Icon = n"Icons.Plus";
				Menu.AddOption(AddPoint, MenuDelegate);

				FHazeContextOption AddPointKeepRotation;
				AddPointKeepRotation.DelegateParam = n"AddPointKeepRotation";
				AddPointKeepRotation.Label = "Add Spline Point Here (Keep Rotation)";
				AddPointKeepRotation.Icon = n"Icons.Plus";
				Menu.AddOption(AddPointKeepRotation, MenuDelegate);

				FHazeContextOption SelectPointsBeforeHere;
				SelectPointsBeforeHere.DelegateParam = n"SelectPointsBeforeHere";
				SelectPointsBeforeHere.Label = "Select All Points Before Here";
				Menu.AddOption(SelectPointsBeforeHere, MenuDelegate);

				FHazeContextOption SelectPointsAfterHere;
				SelectPointsAfterHere.DelegateParam = n"SelectPointsAfterHere";
				SelectPointsAfterHere.Label = "Select All Points After Here";
				Menu.AddOption(SelectPointsAfterHere, MenuDelegate);
			}

			FHazeContextOption SelectAllPoints;
			SelectAllPoints.DelegateParam = n"SelectAllPoints";
			SelectAllPoints.Label = "Select All Spline Points";
			Menu.AddOption(SelectAllPoints, MenuDelegate);
		}

		Menu.BeginSection("Edit");

		{
			FHazeContextOption CutPoint;
			CutPoint.Icon = n"GenericCommands.Cut";
			CutPoint.DelegateParam = n"CutPoint";
			if (Selection.GetSelectedCount() > 1)
			{
				CutPoint.Label = f"Cut {Selection.GetSelectedCount()} Spline Points";
			}
			else
			{
				CutPoint.Label = "Cut Spline Point";
				CutPoint.bDisabled = Selection.IsEmpty();
			}
			Menu.AddOption(CutPoint, MenuDelegate);
		}

		{
			FHazeContextOption CopyPoint;
			CopyPoint.Icon = n"GenericCommands.Copy";
			CopyPoint.DelegateParam = n"CopyPoint";
			if (Selection.GetSelectedCount() > 1)
			{
				CopyPoint.Label = f"Copy {Selection.GetSelectedCount()} Spline Points";
			}
			else
			{
				CopyPoint.Label = "Copy Spline Point";
				CopyPoint.bDisabled = Selection.IsEmpty();
			}
			Menu.AddOption(CopyPoint, MenuDelegate);
		}

		{
			FHazeContextOption SelectAllPointsBeforePoint;
			SelectAllPointsBeforePoint.DelegateParam = n"SelectAllPointsBeforePoint";
			SelectAllPointsBeforePoint.bDisabled = Selection.GetSelectedCount() > 1 || Selection.GetSelectedCount() == 0;
			SelectAllPointsBeforePoint.Label = f"Select All Points Before Point";
			Menu.AddOption(SelectAllPointsBeforePoint, MenuDelegate);
		}

		{
			FHazeContextOption SelectAllPointsAfterPoint;
			SelectAllPointsAfterPoint.DelegateParam = n"SelectAllPointsAfterPoint";
			SelectAllPointsAfterPoint.bDisabled = Selection.GetSelectedCount() > 1 || Selection.GetSelectedCount() == 0;
			SelectAllPointsAfterPoint.Label = f"Select All Points After Point";
			Menu.AddOption(SelectAllPointsAfterPoint, MenuDelegate);
		}

		{
			FHazeContextOption SnapSelectionToGround;
			SnapSelectionToGround.DelegateParam = n"SnapSelectionToGround";
			SnapSelectionToGround.Label = f"Snap Selection To Ground";
			SnapSelectionToGround.bDisabled = Selection.GetSelectedCount() == 0;
			Menu.AddOption(SnapSelectionToGround, MenuDelegate);
		}

		{
			FHazeContextOption MirrorSelectionX;
			MirrorSelectionX.DelegateParam = n"MirrorSelectionX";
			MirrorSelectionX.Label = f"Mirror Selection X values";
			MirrorSelectionX.bDisabled = Selection.GetSelectedCount() == 0;
			Menu.AddOption(MirrorSelectionX, MenuDelegate);
		}

		{
			FHazeContextOption MirrorSelectionY;
			MirrorSelectionY.DelegateParam = n"MirrorSelectionY";
			MirrorSelectionY.Label = f"Mirror Selection Y values";
			MirrorSelectionY.bDisabled = Selection.GetSelectedCount() == 0;
			Menu.AddOption(MirrorSelectionY, MenuDelegate);
		}

		{
			FHazeContextOption MirrorSelectionZ;
			MirrorSelectionZ.DelegateParam = n"MirrorSelectionZ";
			MirrorSelectionZ.Label = f"Mirror Selection Z values";
			MirrorSelectionZ.bDisabled = Selection.GetSelectedCount() == 0;
			Menu.AddOption(MirrorSelectionZ, MenuDelegate);
		}

		bool bValidClipboard = SplineEditing::HasSplinePointsInClipboard();

		{
			FHazeContextOption PasteRelative;
			PasteRelative.Icon = n"GenericCommands.Paste";
			PasteRelative.DelegateParam = n"PasteRelative";
			PasteRelative.bDisabled = !bValidClipboard;
			PasteRelative.Label = "Paste Spline Points Here";
			PasteRelative.Tooltip = "Paste spline points from the clipboard, moving them to be relative to the clicked spline location. Similar to 'Paste Here'.";
			Menu.AddOption(PasteRelative, MenuDelegate);
		}

		{
			FHazeContextOption PasteWorld;
			PasteWorld.Icon = n"GenericCommands.Paste";
			PasteWorld.DelegateParam = n"PasteWorld";
			PasteWorld.bDisabled = !bValidClipboard;
			PasteWorld.Label = "Paste Spline Points (World)";
			PasteWorld.Tooltip = "Paste spline points from the clipboard at the world location they had when copied.";
			Menu.AddOption(PasteWorld, MenuDelegate);
		}

		{
			FHazeContextOption PasteReplace;
			PasteReplace.Icon = n"GenericCommands.Rename";
			PasteReplace.DelegateParam = n"PasteReplace";
			PasteReplace.bDisabled = !bValidClipboard || Selection.IsEmpty();
			PasteReplace.Label = "Replace Spline Points from Clipboard";
			PasteReplace.Tooltip = "Replace the selected spline points with the spline points currently in the clipboard.";
			Menu.AddOption(PasteReplace, MenuDelegate);
		}

		{
			FHazeContextOption PasteReplaceWorld;
			PasteReplaceWorld.Icon = n"GenericCommands.Rename";
			PasteReplaceWorld.DelegateParam = n"PasteReplaceWorld";
			PasteReplaceWorld.bDisabled = !bValidClipboard || Selection.IsEmpty();
			PasteReplaceWorld.Label = "Replace Spline Points from Clipboard (World)";
			PasteReplaceWorld.Tooltip = "Replace the selected spline points with the spline points currently in the clipboard,\nat the original world position those points had when copied.";
			Menu.AddOption(PasteReplaceWorld, MenuDelegate);
		}

		{
			FHazeContextOption DuplicatePoint;
			DuplicatePoint.Icon = n"GenericCommands.Duplicate";
			DuplicatePoint.DelegateParam = n"DuplicatePoint";
			if (Selection.GetSelectedCount() > 1)
			{
				DuplicatePoint.Label = f"Duplicate {Selection.GetSelectedCount()} Spline Points";
			}
			else
			{
				DuplicatePoint.Label = "Duplicate Spline Point";
				DuplicatePoint.bDisabled = Selection.IsEmpty();
			}
			Menu.AddOption(DuplicatePoint, MenuDelegate);
		}

		{
			FHazeContextOption DeletePoint;
			DeletePoint.Icon = n"GenericCommands.Delete";
			DeletePoint.DelegateParam = n"DeletePoint";
			if (Selection.GetSelectedCount() > 1)
			{
				DeletePoint.Label = f"Delete {Selection.GetSelectedCount()} Spline Points";
			}
			else
			{
				DeletePoint.Label = "Delete Spline Point";
				DeletePoint.bDisabled = Selection.IsEmpty();
			}
			Menu.AddOption(DeletePoint, MenuDelegate);
		}

		Menu.EndSection();

		Menu.BeginSection("Spline");

		{
			FHazeContextOption VisualizeScale;
			VisualizeScale.Type = EHazeContextOptionType::Checkbox;
			VisualizeScale.Label = "Visualize Scale";
			VisualizeScale.bChecked = Spline.EditingSettings.bEnableVisualizeScale;
			VisualizeScale.DelegateParam = n"VisualizeScale";
			Menu.AddOption(VisualizeScale, MenuDelegate);
		}

		
		{
			FHazeContextOption ReverseOrder;
			ReverseOrder.Label = "Reverse Order";
			ReverseOrder.DelegateParam = n"ReverseOrder";
			ReverseOrder.Tooltip = "Reverses the order of all spline points in the spline.";
			Menu.AddOption(ReverseOrder, MenuDelegate);
		}

		Menu.EndSection();

		{
			// Allow extensions to add extra options
			const TArray<UClass> ExtensionClasses = UClass::GetAllSubclassesOf(UHazeSplineContextMenuExtension);

			ValidExtensions.Reset();
			for(auto ExtensionClass : ExtensionClasses)
			{
				auto Extension = Cast<UHazeSplineContextMenuExtension>(ExtensionClass.DefaultObject);
				if(Extension.IsValidForContextMenu(Menu, Spline, Selection, ClickedPoint, ClickedDistance))
					ValidExtensions.Add(Extension);
			}

			if(!ValidExtensions.IsEmpty())
			{
				for(auto Extension : ValidExtensions)
				{
					const FString SectionName = Extension.GetSectionName();
					Menu.BeginSection(SectionName);
					Extension.GenerateContextMenu(Menu, Spline, MenuDelegate, Selection, ClickedPoint, ClickedDistance);
					Menu.EndSection();
				}
			}
		}
	}

	UFUNCTION()
	void HandleContextOptionClicked(FHazeContextOption Option)
	{
		FScopeIsRunningSplineEditorCode ScopeEditorCode;
		UHazeSplineComponent Spline = MenuSpline.Get();
		UHazeSplineSelection Selection = MenuSelection;

		FName OptionName = Option.DelegateParam;
		if (OptionName == n"AddPoint")
		{
			FSplineContextTransaction Transaction(this, "Add New Spline Point");
			int NewPointIndex = SplineEditing::InsertPointAtDistance(Spline, MenuClickedDistance);
			if (NewPointIndex != -1)
				SplineEditing::SelectSplinePoint(NewPointIndex);
		}
		else if (OptionName == n"AddPointKeepRotation")
		{
			FSplineContextTransaction Transaction(this, "Add New Spline Point (Keep Rotation)");
			int NewPointIndex = SplineEditing::InsertPointAtDistance(Spline, MenuClickedDistance, true);
			if (NewPointIndex != -1)
				SplineEditing::SelectSplinePoint(NewPointIndex);
		}
		else if (OptionName == n"SelectAllPoints")
		{
			FSplineContextTransaction Transaction(this, "Select All Spline Points", false);
			Selection.Modify();
			Selection.Clear();
			for (int i = 0, Count = Spline.SplinePoints.Num(); i < Count; ++i)
				Selection.AddPointToSelection(i);
		}
		else if (OptionName == n"DeletePoint")
		{
			FSplineContextTransaction Transaction(this, "Delete Spline Point");

			TArray<int> PointsToDelete = Selection.GetAllSelected();
			PointsToDelete.Sort();
			for (int i = 0, Count = PointsToDelete.Num(); i < Count; ++i)
				SplineEditing::DeleteSplinePoint(Spline, PointsToDelete[i] - i);
			
			SplineEditing::SelectSplinePoint(Math::Min(PointsToDelete[0], Spline.SplinePoints.Num() - 1));
		}
		else if (OptionName == n"OverrideTangent")
		{
			if (!Spline.SplinePoints.IsValidIndex(MenuClickedPoint))
				return;

			const FHazeComputedSplinePoint& ComputedPoint = Spline.ComputedSpline.Points[MenuClickedPoint];
			FHazeSplinePoint& SplinePoint = Spline.SplinePoints[MenuClickedPoint];

			bool bSetOverride = !SplinePoint.bOverrideTangent;

			FSplineContextTransaction Transaction(this, "Set Override Tangents");

			for (int Point : Selection.GetAllSelected())
			{
				if (!Spline.SplinePoints.IsValidIndex(Point))
					continue;
				FHazeSplinePoint& EditPoint = Spline.SplinePoints[Point];
				const FHazeComputedSplinePoint& ComputedEditPoint = Spline.ComputedSpline.Points[Point];
				if (!bSetOverride)
				{
					EditPoint.bOverrideTangent = false;
					EditPoint.bDiscontinuousTangent = false;
					EditPoint.ArriveTangent = FVector::ZeroVector;
					EditPoint.LeaveTangent = FVector::ZeroVector;
				}
				else
				{
					EditPoint.bOverrideTangent = true;
					EditPoint.ArriveTangent = ComputedEditPoint.ArriveTangent;
					EditPoint.LeaveTangent = ComputedEditPoint.LeaveTangent;
				}
			}
		}
		else if (OptionName == n"DiscontinuousTangent")
		{
			if (!Spline.SplinePoints.IsValidIndex(MenuClickedPoint))
				return;

			FHazeSplinePoint& SplinePoint = Spline.SplinePoints[MenuClickedPoint];
			bool bSetDiscontinuous = !SplinePoint.bDiscontinuousTangent;

			FSplineContextTransaction Transaction(this, "Set Discontinuous Tangents");

			for (int Point : Selection.GetAllSelected())
			{
				if (!Spline.SplinePoints.IsValidIndex(Point))
					continue;

				FHazeSplinePoint& EditPoint = Spline.SplinePoints[Point];
				if (!bSetDiscontinuous)
				{
					EditPoint.bDiscontinuousTangent = false;
					EditPoint.ArriveTangent = EditPoint.LeaveTangent;
				}
				else
				{
					EditPoint.bDiscontinuousTangent = true;
				}
			}
		}
		else if (OptionName == n"StraightTangents")
		{
			if (!Spline.SplinePoints.IsValidIndex(MenuClickedPoint))
				return;

			FHazeSplinePoint& SplinePoint = Spline.SplinePoints[MenuClickedPoint];
			FSplineContextTransaction Transaction(this, "Calculate Straight Tangents");
			Spline.Modify();

			for (int Point : Selection.GetAllSelected())
				SplineEditing::SetStraightTangentsOnPoint(Spline, Point);

			Spline.UpdateSpline();
		}
		else if (OptionName == n"VisualizeScale")
		{
			FSplineContextTransaction Transaction(this, "Set Visualize Scale", false);
			Spline.Modify();
			Spline.EditingSettings.bEnableVisualizeScale = !Spline.EditingSettings.bEnableVisualizeScale;
			//NotifyPropertyModified(Spline, n"EditingSettings");
		}
		else if (OptionName == n"ReverseOrder")
		{
			FSplineContextTransaction Transaction(this, "Reverse Order");
			Spline.Modify();
			SplineEditing::ReverseSplinePointsOrder(Spline);
		}
		else if (OptionName == n"CopyPoint")
		{
			SplineEditing::CopySelectedPoints(Spline);
		}
		else if (OptionName == n"CutPoint")
		{
			FSplineContextTransaction Transaction(this, "Cut Spline Points");
			SplineEditing::CopySelectedPoints(Spline);
			SplineEditing::DeleteSelectedPoints(Spline);
		}
		else if (OptionName == n"PasteRelative" || OptionName == n"PasteWorld" || OptionName == n"PasteReplace" || OptionName == n"PasteReplaceWorld")
		{
			FSplineContextTransaction Transaction(this, "Paste Spline Points");
			SplineEditing::PasteSplinePoints(
				Spline,
				bRelative = (OptionName != n"PasteWorld" && OptionName != n"PasteReplaceWorld"),
				bReplace = (OptionName == n"PasteReplace" || OptionName == n"PasteReplaceWorld"),
				PlaceDistance = MenuClickedDistance,
			);
		}
		else if (OptionName == n"DuplicatePoint")
		{
			FSplineContextTransaction Transaction(this, "Cut Spline Points");
			SplineEditing::DuplicateSelectedPoints(Spline, FVector::ZeroVector);
		}
		else if (OptionName == n"SelectPointsBeforeHere")
		{
			FSplineContextTransaction Transaction(this, "Selected Spline Points", false);
			SplineEditing::SelectPointsBeforeDistance(Spline, MenuClickedDistance);
		}
		else if (OptionName == n"SelectPointsAfterHere")
		{
			FSplineContextTransaction Transaction(this, "Selected Spline Points", false);
			SplineEditing::SelectPointsAfterDistance(Spline, MenuClickedDistance);
		}
		else if (OptionName == n"SelectAllPointsBeforePoint")
		{
			FSplineContextTransaction Transaction(this, "Selected Spline Points", false);
			SplineEditing::SelectPointsBeforePoint(Spline, MenuClickedPoint);
		}
		else if (OptionName == n"SelectAllPointsAfterPoint")
		{
			FSplineContextTransaction Transaction(this, "Selected Spline Points", false);
			SplineEditing::SelectPointsAfterPoint(Spline, MenuClickedPoint);
		}
		else if (OptionName == n"SnapSelectionToGround")
		{
			FSplineContextTransaction Transaction(this, "Snap Selection To Ground");
			SplineEditing::SnapSelectionToGround(Spline);
		}
		else if (OptionName == n"MirrorSelectionX")
		{
			FSplineContextTransaction Transaction(this, "Mirror Selection X values");
			SplineEditing::MirrorSplinePoints(Spline, true, false, false);
		}
		else if (OptionName == n"MirrorSelectionY")
		{
			FSplineContextTransaction Transaction(this, "Mirror Selection Y values");
			SplineEditing::MirrorSplinePoints(Spline, false, true, false);
		}
		else if (OptionName == n"MirrorSelectionZ")
		{
			FSplineContextTransaction Transaction(this, "Mirror Selection Z values");
			SplineEditing::MirrorSplinePoints(Spline, false, false, true);
		}

		if(!ValidExtensions.IsEmpty())
		{
			for(auto Extension : ValidExtensions)
				Extension.HandleContextOptionClicked(Option, Spline, Selection, MenuClickedDistance, MenuClickedPoint);
		}
	}
}

struct FSplineContextTransaction
{
	UHazeSplineComponent Spline;
	bool bChangedSplinePoints = true;

	FSplineContextTransaction(UHazeSplineContextMenu ContextMenu, FString TransactionName, bool InChangingSplinePoints = true)
	{
		Spline = Cast<UHazeSplineComponent>(ContextMenu.MenuSpline.Get());
		bChangedSplinePoints = InChangingSplinePoints;
		if (Spline != nullptr)
		{
			Editor::BeginTransaction(TransactionName);
			Spline.Modify();
		}
	}

	~FSplineContextTransaction()
	{
		if (Spline != nullptr)
		{
			Spline.UpdateSpline();
			if (Spline.Owner != nullptr)
				Spline.Owner.RerunConstructionScripts();
			Editor::EndTransaction();
			Editor::RedrawAllViewports();
			if (bChangedSplinePoints)
				Editor::NotifyPropertyModified(Spline, n"SplinePoints");
		}
	}
};

#if EDITOR
UCLASS(NotBlueprintable, Abstract)
class UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(
		FHazeContextMenu& Menu,
		UHazeSplineComponent Spline,
		UHazeSplineSelection Selection,
		int ClickedPoint = -1,
		float ClickedDistance = -1.0
	) const
	{
		devError(f"{Class} does not override IsValidForContextMenu, and will never be valid!");
		return false;
	}

	FString GetSectionName() const
	{
		return Class.Name.ToString();
	}

	void GenerateContextMenu(
		FHazeContextMenu& Menu,
		UHazeSplineComponent Spline,
		FHazeContextDelegate MenuDelegate,
		UHazeSplineSelection Selection,
		int ClickedPoint = -1,
		float ClickedDistance = -1.0
	)
	{
		devError(f"{Class} does not override GenerateContextMenu!");
	}

	void HandleContextOptionClicked(
		FHazeContextOption Option,
		UHazeSplineComponent Spline,
		UHazeSplineSelection Selection,
		float MenuClickedDistance,
		int MenuClickedPoint
	)
	{
		devError(f"{Class} does not override HandleContextOptionClicked!");
	}

	/**
	 * Adds an editor component instance to the Spline owner actor at the clicked distance.
	 * @param Spline The spline component we want to add a component on.
	 * @param DistanceAlongSpline Where on the spline we want to add the component.
	 * @param ComponentClass The class we want to add an instance of on the spline.
	 * @param bSetScaleToOne if false, we copy the scale at the distance along the spline to the component. If true, we instead set the scale to always be (1, 1, 1) to not scale the component.
	 * @param bSelect Should we select the new component immediately?
	 * @return The created component instance.
	 */
	protected USceneComponent AddComponentToSpline(UHazeSplineComponent Spline, float DistanceAlongSpline, TSubclassOf<USceneComponent> ComponentClass, bool bSetScaleToOne = true, bool bSelect = true) const
	{
		check(!Editor::IsPlaying());
		USceneComponent AddedComponent = Editor::AddInstanceComponentInEditor(Spline.Owner, ComponentClass, NAME_None);

		if(AddedComponent == nullptr)
			return nullptr;

		FTransform Transform = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);

		if(bSetScaleToOne)
			Transform.Scale3D = FVector::OneVector;

		AddedComponent.SetWorldTransform(Transform);
		
		Spline.Owner.Modify();

		if(bSelect)
			Editor::SelectComponent(AddedComponent);

		return AddedComponent;
	}
};
#endif