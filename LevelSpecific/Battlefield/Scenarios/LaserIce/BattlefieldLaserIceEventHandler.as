struct FBattlefieldLaserIceData
{
	UPROPERTY()
	float Alpha;

	UPROPERTY()
	UStaticMeshComponent Mesh;

	FBattlefieldLaserIceData(float NewAlpha, UStaticMeshComponent NewComp)
	{
		Alpha = NewAlpha;
		Mesh = NewComp;
	}
}

UCLASS(Abstract)
class UBattlefieldLaserIceEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartIceDestruction(FBattlefieldLaserIceData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateIceDestruction(FBattlefieldLaserIceData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopIceDestruction(FBattlefieldLaserIceData Params) {}
};