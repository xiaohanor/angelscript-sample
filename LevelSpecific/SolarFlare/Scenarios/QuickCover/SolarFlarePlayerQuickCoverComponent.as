class USolarFlarePlayerQuickCoverComponent : UActorComponent
{
	ASolarFlareQuickCover QuickCover;
	UInteractionComponent InteractionSide;
	bool bQuickCoverActive;

	UPROPERTY()
	FRuntimeFloatCurve FlareDistanceCurve;
	default FlareDistanceCurve.AddDefaultKey(0.0, 0.5);
	default FlareDistanceCurve.AddDefaultKey(1.0, 1.0);

	UFUNCTION()
	void StartQuickCover(UInteractionComponent CurrentInteraction, ASolarFlareQuickCover CurrentCover)
	{
		QuickCover = CurrentCover;
		InteractionSide = CurrentInteraction;
		bQuickCoverActive = true;
	}

	UFUNCTION()
	void StopQuickCover()
	{
		bQuickCoverActive = false;
	}
};