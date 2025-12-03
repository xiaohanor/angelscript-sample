class UIslandOverseerSideChaseDropLandAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(0, 175, 175);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "DropLand";
	}
}