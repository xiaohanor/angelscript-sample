struct FMagicBarrierCollapseParams
{
	UPROPERTY()
	UStaticMeshComponent MeshComp;

	FMagicBarrierCollapseParams(UStaticMeshComponent StaticMeshComponent)
	{
		MeshComp = StaticMeshComponent;
	}
}

UCLASS(Abstract)
class USummitMagicBarrierEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartCollapsing(FMagicBarrierCollapseParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCollapsed(FMagicBarrierCollapseParams Params) {}
}
