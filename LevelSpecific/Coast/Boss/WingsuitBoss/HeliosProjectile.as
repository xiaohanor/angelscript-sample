UCLASS(Abstract)
class AHeliosProjectile : AHazeActor
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnLaunch();
	}

	void OnLaunch()
	{
		UWingsuitBossRocketEffectHandler::Trigger_OnRocketFired(this);
	}

	UFUNCTION()
	void OnExplode()
	{
		UWingsuitBossRocketEffectHandler::Trigger_OnRocketExploded(this);
	}
}