class UBabyDragonTailClimbFreeFormTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"PrimaryLevelAbility";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	default bVisible = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float Range = 200.0;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, Range);

		return true;
	}


};

class UBabyDragonTailClimbFreeFormTargetableVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBabyDragonTailClimbFreeFormTargetableComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UBabyDragonTailClimbFreeFormTargetableComponent>(Component);
		if(Comp == nullptr)
			return;

		DrawWireSphere(Comp.WorldLocation, Comp.Range, FLinearColor::Green, 5, 12);
	}
}