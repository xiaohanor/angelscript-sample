struct FGameShowArenaPlatformArmStartMovingParams
{
	UPROPERTY()
	UStaticMeshComponent PlatformMesh;

	UPROPERTY()
	AGameShowArenaPlatformArm PlatformArmActor;
}

struct FGameShowArenaPlatformArmStopMovingParams
{
	UPROPERTY()
	UStaticMeshComponent PlatformMesh;

	UPROPERTY()
	AGameShowArenaPlatformArm PlatformArmActor;
}

struct FGameShowArenaPlatformArmStartTiltingParams
{
	UPROPERTY()
	UStaticMeshComponent PlatformMesh;

	UPROPERTY()
	AGameShowArenaPlatformArm PlatformArmActor;
}

UCLASS(Abstract)
class UGameShowArenaPlatformArmEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving(FGameShowArenaPlatformArmStartMovingParams MovingParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartTiltingArm(FGameShowArenaPlatformArmStartTiltingParams TiltingParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving(FGameShowArenaPlatformArmStopMovingParams MovingParams)
	{
	}
};