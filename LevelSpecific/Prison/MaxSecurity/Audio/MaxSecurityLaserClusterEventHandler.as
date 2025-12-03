
struct FMaxSecurityLaserClusterChangeParams
{
	UPROPERTY()
	int32 ClusterID;

	UPROPERTY()
	int32 Count;

	UPROPERTY()
	int32 PreviousCount;

	FMaxSecurityLaserClusterChangeParams(){}

	FMaxSecurityLaserClusterChangeParams(int32 ID, int32 Current, int32 Last)
	{
		ClusterID = ID;
		Count = Current;
		PreviousCount = Last;
	}
}

class UMaxSecurityLaserClusterEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaserClusterChange(FMaxSecurityLaserClusterChangeParams Params) {}
}