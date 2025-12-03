struct FAlongSplineComponentArray
{
	TArray<FAlongSplineComponentData> DataArray;
};

struct FAlongSplineComponentData
{
	access Internal = private, UAlongSplineComponentManager;
	
	UAlongSplineComponent Component;
	float DistanceAlongSpline;

	/**
	 * When sorting a looping spline, we fudge the distance along spline value to handle the looping point, and store that here.
	 * Note that this is not actually where the component is on the spline.
	 * @see ActualDistanceAlongSpline
	 */
	access:Internal
	float SortDistanceAlongSpline;

	FAlongSplineComponentData(
		UAlongSplineComponent InComponent,
		float InDistanceAlongSpline,
		float InSortDistanceAlongSpline)
	{
		Component = InComponent;
		DistanceAlongSpline = InDistanceAlongSpline;
		SortDistanceAlongSpline = InSortDistanceAlongSpline;
	}

	int opCmp(FAlongSplineComponentData Other) const
	{
		if(SortDistanceAlongSpline > Other.SortDistanceAlongSpline)
			return 1;
		else
			return -1;
	}
}

/**
 * Automatically created when a AlongSplineComponent is added to a spline if it doesn't already exists
 * Keeps a map of Class to sorted arrays of components in runtime and editor.
 * Known limitations:
 * - Only supports one spline component, and no connections.
 * - No easy way to directly interact with the system, it is designed to be used through the mixins on UHazeSplineComponent.
 * - Components always represent a point, not a start-end range, since this simplifies sorting.
 */
UCLASS(NotBlueprintable, NotPlaceable, HideCategories = "Activation Cooking Tags Navigation")
class UAlongSplineComponentManager : UActorComponent
{
	access Internal = private, UAlongSplineComponentManagerVisualizer, UAlongSplineComponent;
	access FromComponent = private, UAlongSplineComponent;

#if EDITOR
	UPROPERTY(EditInstanceOnly)
	bool bVisualize = true;
#endif

	access:Internal
	bool bInitialized = false;
	private TMap<UClass, FAlongSplineComponentArray> SortedComponentsAlongSpline;
	private UHazeSplineComponent SplineComp;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		ForceInitialize();
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		ForceInitialize();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceInitialize();
	}

	access:Internal
	void ForceInitialize()
	{
		bInitialized = false;
		InitializeSortedComponents();
	}

	access:Internal
	void InitializeSortedComponents()
	{
		check(!bInitialized);

		// Clear out all of the types and arrays
		SortedComponentsAlongSpline.Reset();

		SplineComp = Spline::GetGameplaySpline(Owner, this);

		if(!HasValidSpline())
			return;

		{
			// Add all components to their types array
			TArray<UAlongSplineComponent> Components;
			Owner.GetComponentsByClass(Components);

			for(auto Comp : Components)
			{
				AddAlongSplineComponent(Comp);
				Comp.SnapToSpline(SplineComp);
			}
		}

		// Sort all arrays by distance along spline
		for(auto Components : SortedComponentsAlongSpline)
			Components.Value.DataArray.Sort();

		bInitialized = true;
	}

	private bool HasValidSpline() const
	{
		if(SplineComp == nullptr)
			return false;

		if(SplineComp.SplinePoints.Num() < 2)
			return false;

		if(SplineComp.SplineLength < 1)
			return false;

		return true;
	}

	private void AddAlongSplineComponent(UAlongSplineComponent AlongSplineComp)
	{
		FAlongSplineComponentArray& ComponentArray = SortedComponentsAlongSpline.FindOrAdd(AlongSplineComp.Class);
		const float DistanceAlongSpline = SplineComp.GetClosestSplineDistanceToWorldLocation(AlongSplineComp.WorldLocation);
		ComponentArray.DataArray.Add(FAlongSplineComponentData(AlongSplineComp, DistanceAlongSpline, DistanceAlongSpline));
	}

	access:FromComponent
	void RemoveAlongSplineComponent(UAlongSplineComponent AlongSplineComp)
	{
		if(!SortedComponentsAlongSpline.Contains(AlongSplineComp.Class))
			return;

		FAlongSplineComponentArray& ComponentArray = SortedComponentsAlongSpline[AlongSplineComp.Class];

		for(int i = ComponentArray.DataArray.Num() - 1; i >= 0; i--)
		{
			if(ComponentArray.DataArray[i].Component != AlongSplineComp)
				continue;

			ComponentArray.DataArray.RemoveAt(i);
		}

		if(ComponentArray.DataArray.IsEmpty())
			SortedComponentsAlongSpline.Remove(AlongSplineComp.Class);
	}

	/**
	* Find the closest AlongSplineComponent on the spline that matches Type
	* @param Type What class we want to search for
	* @param bIncludeSubclasses If false, only the exact class entered will be used. If true, any subclass of that type is also used.
	* @param DistanceAlongSpline Where on the spline we are searching
	* @return The found component and its' distance along the spline. Can be unset.
	*/
	TOptional<FAlongSplineComponentData> FindClosestComponentAlongSpline(
		TSubclassOf<UAlongSplineComponent> Type,
		bool bIncludeSubclasses,
		float DistanceAlongSpline
	) const
	{
		TArray<FAlongSplineComponentData> DataArray;

		if(!GetComponentsAlongSplineForType(Type, bIncludeSubclasses, DataArray))
			return TOptional<FAlongSplineComponentData>();

		return FindClosestComponentAlongSplineInternal(DataArray, DistanceAlongSpline);
	}

	/**
	* Find the previous AlongSplineComponent on the spline that matches Type
	* @param Type What class we want to search for
	* @param bIncludeSubclasses If false, only the exact class entered will be used. If true, any subclass of that type is also used.
	* @param DistanceAlongSpline Where on the spline we are searching
	* @return The found component and its' distance along the spline. Can be unset.
	*/
	TOptional<FAlongSplineComponentData> FindPreviousComponentAlongSpline(
		TSubclassOf<UAlongSplineComponent> Type,
		bool bIncludeSubclasses,
		float DistanceAlongSpline
	) const
	{
		TArray<FAlongSplineComponentData> DataArray;

		if(!GetComponentsAlongSplineForType(Type, bIncludeSubclasses, DataArray))
			return TOptional<FAlongSplineComponentData>();

		return FindPreviousComponentAlongSplineInternal(DataArray, DistanceAlongSpline);
	}

	/**
	* Find the next AlongSplineComponent on the spline that matches Type
	* @param Type What class we want to search for
	* @param bIncludeSubclasses If false, only the exact class entered will be used. If true, any subclass of that type is also used.
	* @param DistanceAlongSpline Where on the spline we are searching
	* @return The found component and its' distance along the spline. Can be unset.
	*/
	TOptional<FAlongSplineComponentData> FindNextComponentAlongSpline(
		TSubclassOf<UAlongSplineComponent> Type,
		bool bIncludeSubclasses,
		float DistanceAlongSpline
	) const
	{
		TArray<FAlongSplineComponentData> DataArray;

		if(!GetComponentsAlongSplineForType(Type, bIncludeSubclasses, DataArray))
			return TOptional<FAlongSplineComponentData>();

		return FindNextComponentAlongSplineInternal(DataArray, DistanceAlongSpline);
	}

	/**
	* Find the AlongSplineComponents that are before and after DistanceAlongSpline of any type
	* Note that Previous and Next might be nullptr if there is no component before or after DistanceAlongSpline
	* @param Type What class we want to search for
	* @param bIncludeSubclasses If false, only the exact class entered will be used. If true, any subclass of that type is also used.
	* @param DistanceAlongSpline Where on the spline we are searching
	* @param Previous The previous component before DistanceAlongSpline. Can be unset if there is none
	* @param Next The next component after DistanceAlongSpline. Can be unset if there is none
	* @param Alpha Linear value of the progress DistanceAlongSpline is between Previous and Next
	* @return True if we found two valid components, otherwise false, even if one component was found
	*/
	bool FindAdjacentComponentsAlongSpline(
		TSubclassOf<UAlongSplineComponent> Type,
		bool bIncludeSubclasses,
		float DistanceAlongSpline,
		TOptional<FAlongSplineComponentData>&out OutPrevious,
		TOptional<FAlongSplineComponentData>&out OutNext,
		float&out OutAlpha
	) const
	{
		TArray<FAlongSplineComponentData> DataArray;

		if(!GetComponentsAlongSplineForType(Type, bIncludeSubclasses, DataArray))
			return false;

		return FindAdjacentComponentsAlongSplineInternal(DataArray, DistanceAlongSpline, OutPrevious, OutNext, OutAlpha);
	}

	/**
	* Find all components that lie within a range of distances.
	* @param Type What class we want to search for.
	* @param bIncludeSubclasses If false, only the exact class entered will be used. If true, any subclass of that type is also used.
	* @param Range The minimum and maximum DistanceAlongSpline that we want to find components within.
	* @param OutResults An array of components within the Range.
	* @return True if we found at least 1 component in the Range.
	*/
	bool FindComponentsInRangeAlongSpline(
		TSubclassOf<UAlongSplineComponent> Type,
		bool bIncludeSubclasses,
		FHazeRange Range,
		TArray<FAlongSplineComponentData>&out OutResults
	) const
	{
		TArray<FAlongSplineComponentData> DataArray;

		if(!GetComponentsAlongSplineForType(Type, bIncludeSubclasses, DataArray))
			return false;

		return FindComponentsInRangeAlongSplineInternal(DataArray, Range, OutResults);
	}

	private TOptional<FAlongSplineComponentData> FindClosestComponentAlongSplineInternal(TArray<FAlongSplineComponentData> Components, float DistanceAlongSpline) const
	{
		if(Components.Num() == 0)
			return TOptional<FAlongSplineComponentData>();

		if(Components.Num() == 1)
			return Components[0];

		if(!SplineComp.IsClosedLoop())
		{
			if(DistanceAlongSpline < Components[0].SortDistanceAlongSpline)
				return Components[0];

			if(DistanceAlongSpline > Components.Last().SortDistanceAlongSpline)
				return Components.Last();
		}

		FAlongSplineComponentData Previous;
		FAlongSplineComponentData Next;
		if(!BinarySearchClosestPair(Components, DistanceAlongSpline, Previous, Next))
			return TOptional<FAlongSplineComponentData>();

		return GetClosestOfPair(Previous, Next, DistanceAlongSpline);
	}

	private TOptional<FAlongSplineComponentData> FindPreviousComponentAlongSplineInternal(TArray<FAlongSplineComponentData> Components, float DistanceAlongSpline) const
	{
		if(Components.Num() == 0)
			return TOptional<FAlongSplineComponentData>();

		if(!SplineComp.IsClosedLoop())
		{
			// We are behind the first component, so we have no previous component
			if(DistanceAlongSpline < Components[0].SortDistanceAlongSpline)
				return TOptional<FAlongSplineComponentData>();
		}

		if(Components.Num() == 1)
			return Components[0];

		if(!SplineComp.IsClosedLoop())
		{
			if(DistanceAlongSpline > Components.Last().SortDistanceAlongSpline)
				return Components.Last();
		}

		FAlongSplineComponentData Previous;
		FAlongSplineComponentData Next;
		if(!BinarySearchClosestPair(Components, DistanceAlongSpline, Previous, Next))
			return TOptional<FAlongSplineComponentData>();

		return Previous;
	}

	private TOptional<FAlongSplineComponentData> FindNextComponentAlongSplineInternal(TArray<FAlongSplineComponentData> Components, float DistanceAlongSpline) const
	{
		if(Components.Num() == 0)
			return TOptional<FAlongSplineComponentData>();

		if(!SplineComp.IsClosedLoop())
		{
			// We are ahead of the last component, so we have no next component
			if(DistanceAlongSpline > Components.Last().SortDistanceAlongSpline)
				return TOptional<FAlongSplineComponentData>();
		}

		if(Components.Num() == 1)
			return Components[0];

		if(!SplineComp.IsClosedLoop())
		{
			if(DistanceAlongSpline < Components[0].SortDistanceAlongSpline)
				return Components[0];
		}

		FAlongSplineComponentData Previous;
		FAlongSplineComponentData Next;
		if(!BinarySearchClosestPair(Components, DistanceAlongSpline, Previous, Next))
			return TOptional<FAlongSplineComponentData>();

		return Next;
	}

	private bool FindAdjacentComponentsAlongSplineInternal(
		TArray<FAlongSplineComponentData> Components,
		float DistanceAlongSpline,
		TOptional<FAlongSplineComponentData>&out OutPrevious,
		TOptional<FAlongSplineComponentData>&out OutNext,
		float&out OutAlpha
	) const
	{
		if(Components.Num() == 0)
		{
			OutPrevious = TOptional<FAlongSplineComponentData>();
			OutNext = TOptional<FAlongSplineComponentData>();
			OutAlpha = 0;
			return false;
		}

		if(Components.Num() == 1)
		{
			OutPrevious = TOptional<FAlongSplineComponentData>();
			OutNext = Components[0];
			OutAlpha = 1;
			return false;
		}

		if(!SplineComp.IsClosedLoop())
		{
			if(DistanceAlongSpline < Components[0].SortDistanceAlongSpline)
			{
				OutPrevious = Components[0];
				OutNext = Components[1];
				OutAlpha = 0;
				return true;
			}

			if(DistanceAlongSpline > Components.Last().SortDistanceAlongSpline)
			{
				OutPrevious = Components[Components.Num() - 2];
				OutNext = Components[Components.Num() - 1];
				OutAlpha = 1;
				return true;
			}
		}

		FAlongSplineComponentData PreviousData;
		FAlongSplineComponentData NextData;
		if(!BinarySearchClosestPair(Components, DistanceAlongSpline, PreviousData, NextData))
			return false;

		OutPrevious = PreviousData;
		OutNext = NextData;

		OutAlpha = Math::NormalizeToRange(DistanceAlongSpline, PreviousData.SortDistanceAlongSpline, NextData.SortDistanceAlongSpline);

		return true;
	}

	private bool FindComponentsInRangeAlongSplineInternal(TArray<FAlongSplineComponentData> Components, FHazeRange Range, TArray<FAlongSplineComponentData>&out OutResults) const
	{
		if(Components.Num() == 0)
		{
			OutResults = TArray<FAlongSplineComponentData>();
			return false;
		}

		FHazeRange DistanceRange = Range;

		if(DistanceRange.Min == DistanceRange.Max)
		{
			OutResults = TArray<FAlongSplineComponentData>();
			return false;
		}

		// Make sure that Min is smaller than Max
		if(DistanceRange.Min > DistanceRange.Max)
		{
			const float Min = DistanceRange.Min;
			DistanceRange.Min = DistanceRange.Max;
			DistanceRange.Max = Min;
		}

		for(auto Component : Components)
		{
			if(DistanceRange.IsInRange(Component.SortDistanceAlongSpline))
				OutResults.Add(Component);
		}

		return !OutResults.IsEmpty();
	}

	private bool GetComponentsAlongSplineForType(TSubclassOf<UAlongSplineComponent> Type, bool bIncludeSubclasses, TArray<FAlongSplineComponentData>&out OutArray) const
	{
		if(SortedComponentsAlongSpline.Num() == 0)
			return false;

		if(bIncludeSubclasses)
		{
			for(const auto& TypeComponents : SortedComponentsAlongSpline)
			{
				if(TypeComponents.Key.IsChildOf(Type))
					OutArray.Append(TypeComponents.Value.DataArray);
			}
		}
		else
		{
			// This is a copy of the array, which is bad, but required since the looping spline handling requires us to add to this array anyway before returning
			FAlongSplineComponentArray ComponentsArray;
			if(!SortedComponentsAlongSpline.Find(Type, ComponentsArray))
				return false;

			OutArray = ComponentsArray.DataArray;
		}

		if(OutArray.IsEmpty())
			return false;

		if(SplineComp.IsClosedLoop())
		{
			// On looping splines, we add fake points at the start and end
			FAlongSplineComponentData BeforeFirst = OutArray.Last();
			FAlongSplineComponentData AfterLast = OutArray[0];

			BeforeFirst.SortDistanceAlongSpline = -(SplineComp.SplineLength - BeforeFirst.DistanceAlongSpline);
			AfterLast.SortDistanceAlongSpline = SplineComp.SplineLength + AfterLast.DistanceAlongSpline;

			OutArray.Insert(BeforeFirst, 0);
			OutArray.Add(AfterLast);
		}

		return true;
	}

	/**
	 * Binary search to find the closest component ahead and behind the DistanceAlongSpline
	 * Should be considered an internal function, and always check that Components has
	 * at least 2 elements, since otherwise we can't find a pair.
	 */
	private bool BinarySearchClosestPair(
		TArray<FAlongSplineComponentData> Components,
		float DistanceAlongSpline,
		FAlongSplineComponentData&out OutPrevious,
		FAlongSplineComponentData&out OutNext
	) const
	{
		if(!ensure(Components.Num() >= 2))
			return false;

		int Low = 0;
		int High = Components.Num() - 1;
		int Middle = 0;

		while(Low < High)
		{
			Middle = Math::IntegerDivisionTrunc(Low + High, 2);

			if(DistanceAlongSpline < Components[Middle].SortDistanceAlongSpline)
			{
				if(Middle > 0 && DistanceAlongSpline > Components[Middle - 1].SortDistanceAlongSpline)
				{
					OutPrevious = Components[Middle - 1];
					OutNext = Components[Middle];
					return true;
				}

				High = Middle;
			}
			else
			{
				if(Middle < Components.Num() - 1 && DistanceAlongSpline < Components[Middle + 1].SortDistanceAlongSpline)
				{
					OutPrevious = Components[Middle];
					OutNext = Components[Middle + 1];
					return true;
				}

				Low = Middle + 1;
			}
		}

		devError("Failed to find a valid pair!");
		return false;
	}

	private const FAlongSplineComponentData& GetClosestOfPair(FAlongSplineComponentData A, FAlongSplineComponentData B, float DistanceAlongSpline) const
	{
		// No need to Abs since A and B should be sorted so that (A < DistanceAlongSpline < B)
		check(A.SortDistanceAlongSpline <= B.SortDistanceAlongSpline);
		if(DistanceAlongSpline - A.SortDistanceAlongSpline < B.SortDistanceAlongSpline - DistanceAlongSpline)
			return A;
		else
			return B;
	}
};

#if EDITOR
class UAlongSplineComponentManagerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UAlongSplineComponentManager;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Manager = Cast<UAlongSplineComponentManager>(Component);

		if(!Manager.bVisualize && !Manager.bHazeEditorOnlyDebugBool)
			return;

		Manager.ForceInitialize();

		auto SplineComp = Spline::GetGameplaySpline(Component.Owner);
		
		const auto SplinePosition = SplineComp.GetClosestSplinePositionToLineSegment(
			Editor::EditorViewLocation,
			Editor::EditorViewLocation + Editor::EditorViewRotation.ForwardVector * 5000,
			false
		);

		DrawPoint("", SplinePosition.WorldLocation, 50, FLinearColor::Purple);

		auto Closest = Manager.FindClosestComponentAlongSpline(UAlongSplineComponent, true, SplinePosition.CurrentSplineDistance);
		if(Closest.IsSet())
		{
			DrawPoint("Closest", Closest.Value.Component.WorldLocation + FVector::UpVector * 100, 80, FLinearColor::LucBlue);
		}

		TOptional<FAlongSplineComponentData> Previous;
		TOptional<FAlongSplineComponentData> Next;
		float Alpha;
		if(Manager.FindAdjacentComponentsAlongSpline(UAlongSplineComponent, true, SplinePosition.CurrentSplineDistance, Previous, Next, Alpha))
		{
			if(Previous.IsSet())
			{
				DrawPoint("Previous", Previous.Value.Component.WorldLocation, 100, FLinearColor::Green);
			}

			if(Next.IsSet())
			{
				DrawPoint("Next", Next.Value.Component.WorldLocation, 100, FLinearColor::Red);
			}
		}
	}

	void DrawPoint(FString PointName, FVector Location, float Radius, FLinearColor Color)
	{
		if(!PointName.IsEmpty())
			DrawWorldString(PointName, Location, Color, 2, bCenterText = true);

		DrawWireSphere(Location, Radius, FLinearColor::LerpUsingHSV(Color, FLinearColor::Gray, 0.1));
	}
};
#endif