UCLASS(NotBlueprintable)
class UIslandPlayerPoisonTriggerBoxComponent : UHazeMovablePlayerTriggerComponent
{
	/* 1 means force field will be destroyed in 1 second, 0.5 means 2 seconds etc. */
	UPROPERTY(EditAnywhere)
	float ForceFieldDamagePerSecond = 0.2;

	/* 1 means player will die in 1 second, 0.5 means 2 seconds etc. */
	UPROPERTY(EditAnywhere)
	float PlayerDamagePerSecond = 1.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : GetPlayersInTrigger())
		{
			auto UserComp = UIslandPlayerForceFieldUserComponent::Get(Player);
			if(UserComp == nullptr)
				continue;
			
			UserComp.TakeDamagePoison(DeltaSeconds, ForceFieldDamagePerSecond, PlayerDamagePerSecond);
		}
	}
}