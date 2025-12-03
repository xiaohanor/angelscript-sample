/**
 * Find the closest AlongSplineComponent on the spline that matches Type
 * @param Type What class we want to search for
 * @param bIncludeSubclasses If false, only the exact class entered will be used. If true, any subclass of that type is also used.
 * @param DistanceAlongSpline Where on the spline we are searching
 * @return The found component and its' distance along the spline. Can be unset.
 */
mixin TOptional<FAlongSplineComponentData> FindClosestComponentAlongSpline(
	const UHazeSplineComponent SplineComp,
	TSubclassOf<UAlongSplineComponent> Type,
	bool bIncludeSubclasses,
	float DistanceAlongSpline
)
{
	if(SplineComp == nullptr)
		return TOptional<FAlongSplineComponentData>();

	const auto Manager = UAlongSplineComponentManager::Get(SplineComp.Owner);
	if(Manager == nullptr)
		return TOptional<FAlongSplineComponentData>();

	return Manager.FindClosestComponentAlongSpline(Type, bIncludeSubclasses, DistanceAlongSpline);
}

/**
 * Find the previous AlongSplineComponent on the spline that matches Type
 * @param Type What class we want to search for
 * @param bIncludeSubclasses If false, only the exact class entered will be used. If true, any subclass of that type is also used.
 * @param DistanceAlongSpline Where on the spline we are searching
 * @return The found component and its' distance along the spline. Can be unset.
 */
mixin TOptional<FAlongSplineComponentData> FindPreviousComponentAlongSpline(
	const UHazeSplineComponent SplineComp,
	TSubclassOf<UAlongSplineComponent> Type,
	bool bIncludeSubclasses,
	float DistanceAlongSpline
)
{
	if(SplineComp == nullptr)
		return TOptional<FAlongSplineComponentData>();

	const auto Manager = UAlongSplineComponentManager::Get(SplineComp.Owner);
	if(Manager == nullptr)
		return TOptional<FAlongSplineComponentData>();

	return Manager.FindPreviousComponentAlongSpline(Type, bIncludeSubclasses, DistanceAlongSpline);
}

/**
 * Find the next AlongSplineComponent on the spline that matches Type
 * @param Type What class we want to search for
 * @param bIncludeSubclasses If false, only the exact class entered will be used. If true, any subclass of that type is also used.
 * @param DistanceAlongSpline Where on the spline we are searching
 * @return The found component and its' distance along the spline. Can be unset.
 */
mixin TOptional<FAlongSplineComponentData> FindNextComponentAlongSpline(
	const UHazeSplineComponent SplineComp,
	TSubclassOf<UAlongSplineComponent> Type,
	bool bIncludeSubclasses,
	float DistanceAlongSpline
)
{
	if(SplineComp == nullptr)
		return TOptional<FAlongSplineComponentData>();

	const auto Manager = UAlongSplineComponentManager::Get(SplineComp.Owner);
	if(Manager == nullptr)
		return TOptional<FAlongSplineComponentData>();

	return Manager.FindNextComponentAlongSpline(Type, bIncludeSubclasses, DistanceAlongSpline);
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
mixin bool FindAdjacentComponentsAlongSpline(
	const UHazeSplineComponent SplineComp,
	TSubclassOf<UAlongSplineComponent> Type,
	bool bIncludeSubclasses,
	float DistanceAlongSpline,
	TOptional<FAlongSplineComponentData>&out Previous,
	TOptional<FAlongSplineComponentData>&out Next,
	float&out Alpha
)
{
	if(SplineComp == nullptr)
		return false;

	const auto Manager = UAlongSplineComponentManager::Get(SplineComp.Owner);
	if(Manager == nullptr)
		return false;

	return Manager.FindAdjacentComponentsAlongSpline(Type, bIncludeSubclasses, DistanceAlongSpline, Previous, Next, Alpha);
}

/**
 * Find all components that lie within a range of distances.
 * @param Type What class we want to search for.
 * @param bIncludeSubclasses If false, only the exact class entered will be used. If true, any subclass of that type is also used.
 * @param Range The minimum and maximum DistanceAlongSpline that we want to find components within.
 * @param OutResults An array of components within the Range.
 * @return True if we found at least 1 component in the Range.
 */
mixin bool FindComponentsInRangeAlongSpline(
	const UHazeSplineComponent SplineComp,
	TSubclassOf<UAlongSplineComponent> Type,
	bool bIncludeSubclasses,
	FHazeRange Range,
	TArray<FAlongSplineComponentData>&out OutResults
)
{
	if(SplineComp == nullptr)
		return false;

	const auto Manager = UAlongSplineComponentManager::Get(SplineComp.Owner);
	if(Manager == nullptr)
		return false;

	return Manager.FindComponentsInRangeAlongSpline(Type, bIncludeSubclasses, Range, OutResults);
}