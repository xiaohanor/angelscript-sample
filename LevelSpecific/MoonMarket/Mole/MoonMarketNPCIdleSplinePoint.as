class UMoonMarketNPCIdleSplinePoint : UAlongSplineComponent
{
	default bSnapRotation = false;

	UPROPERTY(EditInstanceOnly)
	bool bTalkingPoint = false;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bTalkingPoint", EditConditionHides))
	AMoonMarketMole MoleToTalkTo;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugArrow(WorldLocation, WorldLocation + ForwardVector * 200, 500, FLinearColor::Red, 10, bDrawInForeground = false);
	}
#endif
};