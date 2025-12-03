UCLASS(Abstract)
class UTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Tutorial);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	private bool bCompleted = false;

	void SetTutorialCompleted()
	{
		bCompleted = true;
	}

	bool IsOverlappingTutorialVolume() const
	{
		TArray<AActor> Overlaps;
		Player.GetOverlappingActors(Overlaps, ATutorialVolume);

		for (auto Volume : Overlaps)
		{
			auto TutorialVolume = Cast<ATutorialVolume>(Volume);
			if (TutorialVolume != nullptr && TutorialVolume.TutorialCapability == Class)
			{
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bCompleted)
			return false;
		if (!IsOverlappingTutorialVolume())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bCompleted)
			return true;
		if (!IsOverlappingTutorialVolume())
			return true;
		return false;
	}
};