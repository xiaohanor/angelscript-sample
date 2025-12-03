
event void FOnHitByDashEvent(FTeenDragonGeckoClimbDashImpactParams Params);

struct FTeenDragonGeckoClimbDashImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	AActor ImpactedActor;
};

class UTeenDragonTailGeckoClimbDashImpactResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnHitByDashEvent OnHitByDash;

	UFUNCTION(CrumbFunction)
	void CrumbApplyImpact(FTeenDragonGeckoClimbDashImpactParams Params)
	{
		OnHitByDash.Broadcast(Params);
	}
};