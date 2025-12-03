class UGravityBladeOpportunityFailKillPlayerAnimNotify : UAnimNotify
{
#if editor
	default NotifyColor = FColor(200, 40, 0);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "FailKillPlayer";
	}
}

class UGravityBladeOpportunityAttackAlignMoveWindowAnimNotifyState : UAnimNotifyState
{
#if editor
	default NotifyColor = FColor(40, 200, 40);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "AlignMoveWindow ";
	}
}

class UGravityBladeOpportunityAttackAlignRotateWindowAnimNotifyState : UAnimNotifyState
{
#if editor
	default NotifyColor = FColor(200, 200, 40);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "AlignRotateWindow ";
	}
}

