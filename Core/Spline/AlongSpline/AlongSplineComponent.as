UCLASS(Abstract, HideCategories = "Rendering Activation Cooking Tags LOD AssetUserData Navigation Lighting Physics Collision TextureStreaming HLOD")
class UAlongSplineComponent : UHazeEditorRenderedComponent
{
	access Internal = private, UAlongSplineComponentManager, FAlongSplineComponentData, UAlongSplineComponentVisualizer;

	UPROPERTY(EditInstanceOnly, Category = "Along Spline Component")
	protected bool bSnapRotation = true;

#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Along Spline Component")
	FLinearColor EditorColor = FLinearColor::Yellow;

	UPROPERTY(EditAnywhere, Category = "Along Spline Component")
	float EditorRadius = 50;
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		auto Manager = EditorRequireManager();
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		auto SplineComp = Spline::GetGameplaySpline(Owner, this);
		if(SplineComp == nullptr)
			return;
		
		UAlongSplineComponentManager Manager = EditorRequireManager();
		SnapToSpline(SplineComp);

		// Update the distances and sorting
		Manager.ForceInitialize();
	}

	private UAlongSplineComponentManager EditorRequireManager() const
	{
		auto Manager = UAlongSplineComponentManager::Get(Owner);

		if(Manager == nullptr)
			Manager = Editor::AddInstanceComponentInEditor(Owner, UAlongSplineComponentManager, NAME_None);

		return Manager;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Just to make sure that it exists
		UAlongSplineComponentManager::GetOrCreate(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto Manager = UAlongSplineComponentManager::Get(Owner);
		if(Manager != nullptr)
			Manager.RemoveAlongSplineComponent(this);
	}

	access:Internal
	void SnapToSpline(UHazeSplineComponent SplineComp) final
	{
		FTransform Transform = SplineComp.GetClosestSplineWorldTransformToWorldLocation(WorldLocation);
		Transform.SetScale3D(FVector::OneVector);

		if(!bSnapRotation)
			Transform.SetRotation(WorldRotation);

		SetWorldTransform(Transform);
	}

#if EDITOR
	FLinearColor GetDeselectedColor() const
	{
		FLinearColor DeselectedColor = EditorColor;
		DeselectedColor = Math::Lerp(EditorColor, FLinearColor::Gray, 0.5);
		return DeselectedColor;
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		SetVisualizerHitProxy(Name, EVisualizerCursor::Hand);
		DrawWireSphere(WorldLocation, EditorRadius, GetDeselectedColor(), EditorRadius, 4, false);
		//DrawCircle(WorldLocation, EditorRadius, GetDeselectedColor(), 10, ForwardVector);
		ClearHitProxy();
	}

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void CalcBounds(FVector& OutOrigin, FVector& OutBoxExtent, float& OutSphereRadius) const
	{
		OutOrigin = WorldLocation;
		OutBoxExtent = FVector(EditorRadius);
		OutSphereRadius = EditorRadius;
	}
#endif
};

#if EDITOR
/**
 * Helper for easily creating selectable visualizers along a spline
 */
class UAlongSplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UAlongSplineComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto AlongSplineComp = Cast<UAlongSplineComponent>(Component);
		if(AlongSplineComp == nullptr)
			return;

		SetHitProxy(AlongSplineComp.Name, EVisualizerCursor::Hand);

		if(Editor::IsComponentSelected(AlongSplineComp))
			DrawSelectedShape(AlongSplineComp, AlongSplineComp.EditorColor);
		else
			DrawDeselectedShape(AlongSplineComp, AlongSplineComp.GetDeselectedColor());

		ClearHitProxy();
	}

	// Handle when the point with the hit proxy is clicked 
	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		if(EditingComponent == nullptr)
			return false;

		auto AlongSplineComp = UAlongSplineComponent::Get(EditingComponent.Owner, HitProxy);
		if(AlongSplineComp != nullptr)
		{
			Editor::SelectComponent(AlongSplineComp);
			return true;
		}

		return false;
	}

	void DrawSelectedShape(UAlongSplineComponent AlongSplineComp, FLinearColor SelectedColor) const
	{
		DrawWireSphere(AlongSplineComp.WorldLocation, AlongSplineComp.EditorRadius + 1, SelectedColor, AlongSplineComp.EditorRadius + 1, 4);
	}

	void DrawDeselectedShape(UAlongSplineComponent AlongSplineComp, FLinearColor DeselectedColor) const
	{
	}
}
#endif