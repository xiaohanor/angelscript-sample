struct FBattlefieldHoverboardGoingBackwardsSnipeOnWarningIssuedParams
{
	UPROPERTY()
	UHazeSkeletalMeshComponentBase MeshToAttachTo;

	UPROPERTY()
	FName BoneToAttachTo;

	UPROPERTY()
	FRotator LaserWorldRotation;
}

struct FBattlefieldHoverboardGoingBackwardsSnipeOnWarningIgnoredParams
{
	UPROPERTY()
	UHazeSkeletalMeshComponentBase MeshToAttachTo;

	UPROPERTY()
	FName BoneToAttachTo;

	UPROPERTY()
	FRotator SnipeWorldRotation;
}

UCLASS(Abstract)
class UBattlefieldHoverboardGoingBackwardsSnipeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWarningIssued(FBattlefieldHoverboardGoingBackwardsSnipeOnWarningIssuedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWarningIgnored(FBattlefieldHoverboardGoingBackwardsSnipeOnWarningIgnoredParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWarningTimePassed() {}
};