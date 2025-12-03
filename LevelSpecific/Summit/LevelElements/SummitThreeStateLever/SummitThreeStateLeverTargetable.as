#if EDITOR
class USummitThreeStateLeverTargetableVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitThreeStateLeverTargetableComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Lever = Cast<ASummitThreeStateLever>(Component.Owner);
		auto Targetable = Cast<USummitThreeStateLeverTargetableComponent>(Component);
		
		DrawWireSphere(Targetable.WorldLocation, Targetable.MaxRange, FLinearColor::Red);

		DrawWireSphere(Lever.GetPlayerTargetLocation(), 40.0, FLinearColor::LucBlue);
		DrawWorldString("Player Location", Lever.GetPlayerTargetLocation(), FLinearColor::LucBlue);
	}
}
#endif

class USummitThreeStateLeverTargetableComponent : UTargetableComponent
{
	default TargetableCategory = ActionNames::Interaction;

	UPROPERTY(EditAnywhere)
	float MaxRange = 400;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyVisibleRange(Query, MaxRange);
		Targetable::ApplyTargetableRange(Query, MaxRange);

		return true;
	}
}