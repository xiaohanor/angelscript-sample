event void FTundraOtterSonarBlastTriggeredEvent(UTundraPlayerOtterSonarBlastTargetable Targetable);

class UTundraPlayerOtterSonarBlastTargetable : UInteractionComponent
{
	default TargetableCategory = ActionNames::Interaction;
	default UsableByPlayers = EHazeSelectPlayer::Mio;
	default bIsImmediateTrigger = true;
	default MovementSettings = FMoveToParams::NoMovement();

	UPROPERTY()
	FTundraOtterSonarBlastTriggeredEvent OnTriggered;

	UPROPERTY(EditAnywhere)
	bool bLerpOutOnCircle = false;

	UPROPERTY(EditAnywhere)
	float LerpOutCircleRadius = 250.0;
}

#if EDITOR
class UTundraPlayerOtterSonarBlastTargetableVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraPlayerOtterSonarBlastTargetable;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Targetable = Cast<UTundraPlayerOtterSonarBlastTargetable>(Component);

		if(Targetable.bLerpOutOnCircle)
			DrawCircle(Targetable.WorldLocation, Targetable.LerpOutCircleRadius, FLinearColor::Red, 5.0);
	}
}
#endif