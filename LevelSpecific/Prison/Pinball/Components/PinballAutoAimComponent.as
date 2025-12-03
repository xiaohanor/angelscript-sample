event void FPinballAutoAimOnTargeted();

UCLASS(NotBlueprintable)
class UPinballAutoAimComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	protected float Width = 500;

	UPROPERTY(EditAnywhere)
	protected float TargetOffset = 40;

	UPROPERTY(EditAnywhere)
	protected float SideOffset = 0;

	UPROPERTY()
	FPinballAutoAimOnTargeted OnTargeted;

	private TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		SideOffset = Math::Clamp(SideOffset, -Width * 0.5, Width * 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		DisableInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		DisableInstigators.AddUnique(this);
	}

	UFUNCTION(BlueprintCallable)
	void EnableAutoAim(FInstigator Instigator)
	{
		DisableInstigators.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void DisableAutoAim(FInstigator Instigator)
	{
		DisableInstigators.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsAutoAimEnabled() const
	{
		return DisableInstigators.Num() == 0;
	}

	bool IntersectsWithRay(FVector Start, FVector Direction, float Distance, float&out OutDistance) const
	{
		return IntersectsWithDelta(Start, Direction * Distance, OutDistance);
	}

	bool IntersectsWithDelta(FVector Start, FVector Delta, float&out Distance) const
	{
		const FVector End = Start + Delta;
		
		FVector Intersection;
		if(!Math::IsLineSegmentIntersectingPlane(Start, End, UpVector, GetLineLocation(), Intersection))
			return false;

		Intersection = Intersection - GetLineLocation();
		float DistanceFromTarget = Intersection.DotProduct(ForwardVector);
		DistanceFromTarget -= SideOffset;

		DistanceFromTarget = Math::Abs(DistanceFromTarget);

		if(DistanceFromTarget > Width * 0.5)
			return false;

		Distance = DistanceFromTarget;
		return true;
	}

	FVector GetLineLocation() const
	{
		const FVector Down = -UpVector * TargetOffset;
		return WorldLocation + Down;
	}

	void GetAutoAimLine(FVector&out Start, FVector&out End) const
	{
		const FVector Down = -UpVector * TargetOffset;
		Start = WorldLocation + Down - ForwardVector * ((Width * 0.5) - SideOffset);
		End = WorldLocation + Down + ForwardVector * ((Width * 0.5) + SideOffset);
	}

#if EDITOR
	void VisualizeAutoAim(const UHazeScriptComponentVisualizer Visualizer, FVector Location) const
	{
		FVector Left, Right;
		GetAutoAimLine(Left, Right);

		Visualizer.DrawLine(Left, Right, FLinearColor::Yellow, 3);

		Visualizer.DrawWireSphere(Location, 40, FLinearColor::Yellow, 3);

		const FVector InFront = Location - UpVector * 140;
		const FVector OnLine = Location - UpVector * 40;
		Visualizer.DrawArrow(InFront, OnLine, FLinearColor::Yellow, 10, 3);
	}
#endif
}

#if EDITOR
class UPinballAutoAimComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPinballAutoAimComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto AutoAimComp = Cast<UPinballAutoAimComponent>(Component);
		AutoAimComp.VisualizeAutoAim(this, AutoAimComp.WorldLocation);
	}
}
#endif