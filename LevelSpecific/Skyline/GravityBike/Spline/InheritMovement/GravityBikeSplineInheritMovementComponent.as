enum EGravityBikeSplineInheritMovementEnterCondition
{
	OnGround,
	OnEnterZone,
}

enum EGravityBikeSplineInheritMovementExitCondition
{
	OnAir,
	OnOtherGround,
	OnOtherGroundOrAir,
	OnExitZone,
}

UCLASS(NotBlueprintable)
class UGravityBikeSplineInheritMovementComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	EGravityBikeSplineInheritMovementEnterCondition EnterCondition = EGravityBikeSplineInheritMovementEnterCondition::OnGround;

	UPROPERTY(EditAnywhere)
	EGravityBikeSplineInheritMovementExitCondition ExitCondition = EGravityBikeSplineInheritMovementExitCondition::OnOtherGround;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "EnterCondition == EGravityBikeSplineInheritMovementEnterCondition::OnEnterZone || ExitCondition == EGravityBikeSplineInheritMovementExitCondition::OnExitZone"))
	FVector Extent = FVector(1000, 1000, 1000);

	UPROPERTY(EditAnywhere)
	EMovementFollowComponentType FollowType = EMovementFollowComponentType::ResolveCollision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(EnterCondition == EGravityBikeSplineInheritMovementEnterCondition::OnEnterZone)
			GravityBikeSpline::GetInheritMovementManager().EnterZones.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(EnterCondition == EGravityBikeSplineInheritMovementEnterCondition::OnEnterZone)
			GravityBikeSpline::GetInheritMovementManager().EnterZones.RemoveSingle(this);
	}

	bool IsPointInside(FVector Point) const
	{
		const FVector RelativePoint = WorldTransform.InverseTransformPosition(Point);
		return Math::Abs(RelativePoint.X) < Extent.X && Math::Abs(RelativePoint.Y) < Extent.Y && Math::Abs(RelativePoint.Z) < Extent.Z;
	}
};

#if EDITOR
class UGravityBikeSplineInheritMovementComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineInheritMovementComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto InheritComp = Cast<UGravityBikeSplineInheritMovementComponent>(Component);
		if(InheritComp == nullptr)
			return;

		if(InheritComp.EnterCondition == EGravityBikeSplineInheritMovementEnterCondition::OnEnterZone || InheritComp.ExitCondition == EGravityBikeSplineInheritMovementExitCondition::OnExitZone)
		{
			FVector Extent = InheritComp.WorldScale * InheritComp.Extent;
			DrawWireBox(InheritComp.WorldLocation, Extent, InheritComp.ComponentQuat, FLinearColor::DPink, 5, true);
		}
	}
};
#endif