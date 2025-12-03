USTRUCT()
struct FRemoteHackingAnimations
{
	UPROPERTY(EditAnywhere)
	UAnimSequence Launch;
}

USTRUCT()
struct FRemoteHackingStartParams
{
	UPROPERTY(BlueprintReadOnly)
	float TimeToTarget = 0.0;

	UPROPERTY(BlueprintReadOnly)
	FVector TargetLocation;
}

struct FRemoteHackingLaunchTickParams
{
	UPROPERTY()
	FVector TargetLocation;
}