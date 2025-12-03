struct FIslandShieldEaterContainerCylinderMoveEffectParams
{
	UPROPERTY()
	UStaticMeshComponent Cylinder;
}

UCLASS(Abstract)
class UIslandShieldEaterContainerEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly, Transient)
	AIslandShieldEaterContainer Container;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Container = Cast<AIslandShieldEaterContainer>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCylinderMoveIn(FIslandShieldEaterContainerCylinderMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCylinderMoveOut(FIslandShieldEaterContainerCylinderMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldDestroyed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldRegenerated() {}
}