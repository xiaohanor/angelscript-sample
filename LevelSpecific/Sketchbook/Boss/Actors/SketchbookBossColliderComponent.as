class USketchbookBossColliderComponent : UStaticMeshComponent
{
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetWorldLocation(FVector(0, AttachParent.WorldLocation.Y, AttachParent.WorldLocation.Z));
	}
};