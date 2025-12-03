/**
 * Used as fallback in case bomb does not collide with anything or get caught.
 */
class UGameShowArenaBombTimeoutExplosionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	AGameShowArenaBomb Bomb;
	bool bHasExploded = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bomb = Cast<AGameShowArenaBomb>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Bomb.State.Get() != EGameShowArenaBombState::Thrown)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Bomb.State.Get() != EGameShowArenaBombState::Thrown)
			return true;

		if (bHasExploded)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasExploded = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (ActiveDuration > 10)
		{
			Bomb.CrumbExplode(Bomb.ActorLocation);
		}
	}
};