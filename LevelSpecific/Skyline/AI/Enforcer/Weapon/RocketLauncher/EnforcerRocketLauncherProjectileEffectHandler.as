UCLASS(Abstract)
class UEnforcerRocketProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRocketView(FEnforcerRocketProjectileEffectHandlerOnRocketViewData Data) {}
}

struct FEnforcerRocketProjectileEffectHandlerOnRocketViewData
{
	UPROPERTY()
	bool bInView;

	UPROPERTY()
	AHazePlayerCharacter Player;
}