UCLASS(NotBlueprintable, HideCategories = "Rendering Activation Cooking Tags LOD Navigation ComponentTick Disable Visuals Targetable")
class UDentistToothDashAutoAimComponent : UTargetableComponent
{
	default TargetableCategory = n"DentistToothDash";

    UPROPERTY(EditAnywhere, Category = "Dash Auto Aim")
    float MaximumDistance = 1000.0;

    UPROPERTY(EditAnywhere, Category = "Dash Auto Aim")
	float MaximumHorizontalAngle = 45;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, MaximumDistance);

		if(Query.DistanceToTargetable > MaximumDistance)
			return false;

		Targetable::ScoreWantedMovementInput(Query, MaximumHorizontalAngle);

		return Query.Result.bPossibleTarget && Query.Result.Score > 0;
	}
};

#if EDITOR
class UDentistToothDashAutoAimComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDentistToothDashAutoAimComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto AutoAimComp = Cast<UDentistToothDashAutoAimComponent>(Component);
		if(AutoAimComp == nullptr)
			return;

		DrawWireSphere(AutoAimComp.WorldLocation, AutoAimComp.MaximumDistance, FLinearColor::Yellow, 1, 12, true);

		FVector ToView = (Editor::EditorViewLocation - AutoAimComp.WorldLocation).GetSafeNormal2D();
		FVector ArcStartLocation = AutoAimComp.WorldLocation + (ToView * AutoAimComp.MaximumDistance);

		DrawArc(ArcStartLocation, AutoAimComp.MaximumHorizontalAngle * 2, AutoAimComp.MaximumDistance, -ToView, FLinearColor::Green, 20);
	}
}
#endif