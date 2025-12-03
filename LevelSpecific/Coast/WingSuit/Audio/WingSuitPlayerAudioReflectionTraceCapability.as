
class UWingSuitPlayerAudioReflectionTraceCapability : UHazePlayerCapability
{
	AWingSuit PlayerWingSuit;
	UHazeAudioReflectionComponent ReflectionComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerWingSuit = GetWingSuitFromPlayer(Player);
		ReflectionComponent = UHazeAudioReflectionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ReflectionComponent.AddActorToIgnore(PlayerWingSuit);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ReflectionComponent.RemoveActorToIgnore(PlayerWingSuit);
	}
}