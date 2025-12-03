/*
 * Basically a data component to help with creating distance based triggers
 * Used by the player in GravityBikeSplineDistanceTrigger, and by enemies in GravityBikeSplineEnemyFireComponent
 */
UCLASS(NotBlueprintable, HideCategories = "Collision Rendering Activation Cooking Tags LOD Lighting Physics Navigation TextureStreaming HLOD AssetUserData")
class UGravityBikeSplineDistanceTriggerComponent : UHazeEditorRenderedComponent
{
	UPROPERTY(EditAnywhere, Category = "Distance Trigger")
	bool bUseEndExtent = false;

	UPROPERTY(EditAnywhere, Category = "Distance Trigger", Meta = (EditCondition = "bUseEndExtent", EditConditionHides))
	float EndExtent = 500;

	FLinearColor StartColor = FLinearColor::LucBlue;
	FLinearColor EndColor = FLinearColor::Blue;


	private bool bInitialized = false;
	private UHazeSplineComponent SplineComp;
	private float DistanceAlongSpline;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		UpdateEditorLocation();
	}

	void UpdateEditorLocation()
	{
		UpdateSpline();

		const FVector Location = SplineComp.GetClosestSplineWorldLocationToWorldLocation(WorldLocation);
		SetWorldLocation(Location);
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		UpdateSpline();

		if(!HasValidSpline())
			return;

		SetVisualizerHitProxy(Name, EVisualizerCursor::Hand);

		const float StartDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(WorldLocation);
		const FTransform StartTransform = SplineComp.GetWorldTransformAtSplineDistance(StartDistance);
		DrawCircle(StartTransform.Location, 500, StartColor, 30, StartTransform.Rotation.ForwardVector);

		if(bUseEndExtent)
		{
			float EndDistance = DistanceAlongSpline + EndExtent;
			EndDistance = Math::Clamp(EndDistance, 0, SplineComp.SplineLength);

			const FTransform EndTransform = SplineComp.GetWorldTransformAtSplineDistance(EndDistance);
			DrawCircle(EndTransform.Location, 500, EndColor, 30, EndTransform.Rotation.ForwardVector);
		}

		ClearHitProxy();
	}

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void CalcBounds(FVector& OutOrigin, FVector& OutBoxExtent, float& OutSphereRadius) const
	{
		if(!HasValidSpline())
			return;

		auto Spline = Spline::GetGameplaySpline(Owner);
		const float StartDistance = Spline.GetClosestSplineDistanceToWorldLocation(WorldLocation);
		const FVector StartLocation = Spline.GetWorldLocationAtSplineDistance(StartDistance);
		FBox TriggerBounds = FBox::BuildAABB(StartLocation, FVector(500));

		if(bUseEndExtent)
		{
			float EndDistance = DistanceAlongSpline + EndExtent;
			EndDistance = Math::Clamp(EndDistance, 0, Spline.SplineLength);
			const FVector EndLocation = Spline.GetWorldLocationAtSplineDistance(EndDistance);
			TriggerBounds += FBox::BuildAABB(EndLocation, FVector(500));
		}

		OutOrigin = TriggerBounds.Center;
		OutBoxExtent = TriggerBounds.Extent;
		OutSphereRadius = TriggerBounds.Extent.Size();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	void Initialize()
	{
		if(bInitialized)
			return;

		UpdateSpline();

		float EndDistance = DistanceAlongSpline + EndExtent;
		EndDistance = Math::Clamp(EndDistance, 0, SplineComp.SplineLength);
		EndExtent = EndDistance - DistanceAlongSpline;

		bInitialized = true;
	}

	void UpdateSpline()
	{
		SplineComp = Spline::GetGameplaySpline(Owner);

		if(!ensure(HasValidSpline()))
			return;

		EndExtent = Math::Max(EndExtent, 1);
		DistanceAlongSpline = SplineComp.GetClosestSplineDistanceToWorldLocation(WorldLocation);
	}

	bool HasValidSpline() const
	{
		if(SplineComp == nullptr)
			return false;

		if(SplineComp.SplinePoints.Num() < 2)
			return false;

		if(SplineComp.SplineLength < 1)
			return false;

		return true;
	}

	float GetStartDistance() const
	{
		check(HasValidSpline());
		return DistanceAlongSpline;
	}

	float GetEndDistance() const
	{
		check(HasValidSpline());
		return GetStartDistance() + EndExtent;
	}

	UHazeSplineComponent GetSplineComp() const
	{
		check(HasValidSpline());
		return SplineComp;
	}

	int opCmp(UGravityBikeSplineDistanceTriggerComponent Other) const
	{
		if(Other.GetStartDistance() > GetStartDistance())
			return 1;
		else
			return -1;
	}

#if EDITOR
	FString GetDebugString() const
	{
		return f"{Math::RoundToInt(GetStartDistance() / 100)}m";
	}
#endif
};

#if EDITOR
class UGravityBikeSplineDistanceTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineDistanceTriggerComponent;
	
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto TriggerComp = Cast<UGravityBikeSplineDistanceTriggerComponent>(Component);
		if(TriggerComp == nullptr)
			return;

		if(!TriggerComp.HasValidSpline())
			return;

		SetHitProxy(TriggerComp.Name, EVisualizerCursor::Hand);
		Visualize(TriggerComp);
		ClearHitProxy();
	}

	void Visualize(const UGravityBikeSplineDistanceTriggerComponent InTriggerComp)
	{
		if(Editor::IsComponentSelected(InTriggerComp))
		{
			const FTransform StartTransform = InTriggerComp.GetSplineComp().GetWorldTransformAtSplineDistance(InTriggerComp.GetStartDistance());
			DrawCircle(StartTransform.Location, 500, FLinearColor::Yellow, 100, StartTransform.Rotation.ForwardVector);

			if(InTriggerComp.bUseEndExtent)
			{
				const FTransform EndTransform = InTriggerComp.GetSplineComp().GetWorldTransformAtSplineDistance(InTriggerComp.GetEndDistance());
				DrawCircle(EndTransform.Location, 500, ColorDebug::Carrot,100, EndTransform.Rotation.ForwardVector);
			}
		}

		const FTransform StartTransform = InTriggerComp.GetSplineComp().GetWorldTransformAtSplineDistance(InTriggerComp.GetStartDistance());
		DrawWorldString(InTriggerComp.GetDebugString(), StartTransform.Location, InTriggerComp.StartColor);
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(
		FName HitProxy,
		FVector ClickOrigin,
		FVector ClickDirection,
		FKey Key,
	    EInputEvent Event)
	{
		if(EditingComponent != nullptr)
		{
			auto ClickedComponent = UGravityBikeSplineDistanceTriggerComponent::Get(EditingComponent.Owner, HitProxy);
			if(ClickedComponent != nullptr)
			{
				Editor::SelectComponent(ClickedComponent);
				return true;
			}
		}

		return false;
	}
};
#endif