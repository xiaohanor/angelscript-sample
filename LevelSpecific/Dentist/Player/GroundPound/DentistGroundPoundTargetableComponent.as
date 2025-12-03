UCLASS(NotBlueprintable)
class UDentistGroundPoundAutoAimComponent : UTargetableComponent
{
	UPROPERTY(EditAnywhere, Meta = (ClampMin = "0.0"))
	float MoveToRadius = 150;

	// If within this but outside TargetRadius, move us in to the TargetRadius
	UPROPERTY(EditAnywhere, Meta = (ClampMin = "1.0"))
	float MaxRadius = 250;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "1.0"))
	float Height = 500;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		FVector RelativeToTarget = WorldTransform.InverseTransformPositionNoScale(Query.Player.ActorLocation);
		if(RelativeToTarget.Z < 0)
			return false;

		if(RelativeToTarget.Z > Height)
			return false;

		const float HorizontalDistance = RelativeToTarget.Size2D(FVector::UpVector);

		if(HorizontalDistance > MaxRadius)
			return false;

		Targetable::ApplyVisibleRange(Query, 5000);
		Targetable::ApplyDistanceToScore(Query);
		Targetable::RequirePlayerCanReachUnblocked(Query);

		return true;
	}
};

UCLASS(NotBlueprintable)
class UDentistGroundPoundAutoAimComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDentistGroundPoundAutoAimComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto AutoAimComp = Cast<UDentistGroundPoundAutoAimComponent>(Component);
		if(AutoAimComp == nullptr)
			return;

		DrawWireCylinder(AutoAimComp.WorldLocation + AutoAimComp.UpVector * (AutoAimComp.Height * 0.5), AutoAimComp.WorldRotation, FLinearColor::Green, AutoAimComp.MoveToRadius, AutoAimComp.Height * 0.5, 16, 3);
		DrawWireCylinder(AutoAimComp.WorldLocation + AutoAimComp.UpVector * (AutoAimComp.Height * 0.5), AutoAimComp.WorldRotation, FLinearColor::Red, AutoAimComp.MaxRadius, AutoAimComp.Height * 0.5, 16, 3);
	}
};