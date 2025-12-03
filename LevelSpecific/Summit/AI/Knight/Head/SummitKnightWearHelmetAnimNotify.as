class UAnimNotifySummitKnightWearHelmet : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor::Emerald;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Wear helmet";
	}
}
