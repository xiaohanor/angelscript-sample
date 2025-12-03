struct FSummitDarkCavePlatformVelocityParams
{
	UPROPERTY()
	float PlatformSpeed;

	FSummitDarkCavePlatformVelocityParams(float NewPlatformSpeed)
	{
		PlatformSpeed = NewPlatformSpeed;
	}
}

UCLASS(Abstract)
class USummitDarkCavePlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformImpactObject() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformSpawned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformUpdateVelocity(FSummitDarkCavePlatformVelocityParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformDespawned() {}
};