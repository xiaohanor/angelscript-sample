struct FOnCatHeadActivatedParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	UStaticMeshComponent MeshComp;

	FOnCatHeadActivatedParams(FVector NewLoc, UStaticMeshComponent NewMeshComp)
	{
		Location = NewLoc;
		MeshComp = NewMeshComp;
	}
}

UCLASS(Abstract)
class UMoonGateHeadEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCatHeadStartedGlowing(FOnCatHeadActivatedParams Params) {}
};