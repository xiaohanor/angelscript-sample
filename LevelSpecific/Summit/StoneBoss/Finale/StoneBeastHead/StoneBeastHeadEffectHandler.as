struct FStoneBeastHeadParams
{
	UPROPERTY()
	AStoneBeastHead StoneBeastHead;

	FStoneBeastHeadParams(AStoneBeastHead NewHead)
	{
		StoneBeastHead = NewHead;
	}
}


UCLASS(Abstract)
class UStoneBeastHeadEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastTelegraphShake(FStoneBeastHeadParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastStartShake(FStoneBeastHeadParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastSlowDownShake(FStoneBeastHeadParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastStopShake(FStoneBeastHeadParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastTelegraphRoll(FStoneBeastHeadParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastStartRoll(FStoneBeastHeadParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastStopRoll(FStoneBeastHeadParams Params) {}
};