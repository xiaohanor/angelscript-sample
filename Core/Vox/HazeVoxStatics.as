
UFUNCTION(NotBlueprintCallable)
void HazePlayVox(UHazeVoxAsset VoxAsset, TArray<AHazeActor> Actors = TArray<AHazeActor>())
{
	UHazeVoxController Controller = UHazeVoxController::Get();
	FOnHazeVoxAssetPlayingStopped DummyDelegate;
	Controller.Play(VoxAsset, Actors, DummyDelegate, nullptr, EHazeVoxLaneInterruptType::None, false);
}

UFUNCTION(NotBlueprintCallable)
void HazePlayVoxSoftActors(UHazeVoxAsset VoxAsset, TArray<TSoftObjectPtr<AHazeActor>> SoftActors = TArray<TSoftObjectPtr<AHazeActor>>())
{
	TArray<AHazeActor> HardActors;
	for (auto SoftActor : SoftActors)
	{
		if (!devEnsure(IsValid(SoftActor.Get()), "Invalid SoftObject Actor Ref"))
			continue;

		HardActors.Add(SoftActor.Get());
	}

	UHazeVoxController Controller = UHazeVoxController::Get();
	FOnHazeVoxAssetPlayingStopped DummyDelegate;
	Controller.Play(VoxAsset, HardActors, DummyDelegate, nullptr, EHazeVoxLaneInterruptType::None, false);
}

UFUNCTION(Category = "HazeVox")
void HazeVoxStopSystem()
{
	UHazeVoxController Controller = UHazeVoxController::Get();
	Controller.StopVox();
}

UFUNCTION(Category = "HazeVox")
void HazeVoxStartSystem()
{
	UHazeVoxController Controller = UHazeVoxController::Get();
	Controller.StartVox();
}

UFUNCTION(Category = "HazeVox")
void HazeVoxPauseActor(AHazeActor Actor, FInstigator Instigator)
{
	if (Actor == nullptr)
	{
		PrintError("HazeVoxPauseActor called without Actor!");
		return;
	}

	UHazeVoxController Controller = UHazeVoxController::Get();
	Controller.PauseActor(Actor, Instigator);
}

UFUNCTION(Category = "HazeVox")
void HazeVoxResumeActor(AHazeActor Actor, FInstigator Instigator)
{
	if (Actor == nullptr)
	{
		PrintError("HazeVoxResumeActor called without Actor!");
		return;
	}
	UHazeVoxController Controller = UHazeVoxController::Get();
	Controller.ResumeActor(Actor, Instigator);
}

UFUNCTION(Category = "HazeVox")
bool HazeVoxIsActorActive(AHazeActor Actor)
{
	if (Actor == nullptr)
	{
		PrintError("HazeVoxIsActorActive called without actor");
		return false;
	}

	UHazeVoxRunner Runner = UHazeVoxRunner::Get();
	return Runner.IsActorActive(Actor);
}

UFUNCTION(Category = "HazeVox")
void HazeVoxStopAsset(UHazeVoxAsset VoxAsset)
{
	UHazeVoxController Controller = UHazeVoxController::Get();
	Controller.Stop(VoxAsset);
}
