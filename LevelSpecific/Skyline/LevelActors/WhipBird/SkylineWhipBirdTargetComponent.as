class USkylineWhipBirdTargetComponent : USceneComponent
{
	float TargetRadius = 100.0;
	bool bIsOccupied = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Manager = TListedActors<ASkylineWhipBirdManager>().Single;
		if (Manager == nullptr)
			Manager = SpawnActor(ASkylineWhipBirdManager);

		Manager.AddTarget(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
/*
		if (bIsOccupied)
			Debug::DrawDebugPoint(WorldLocation, 20.0, FLinearColor::Red, 0.0);
		else
			Debug::DrawDebugPoint(WorldLocation, 20.0, FLinearColor::Green, 0.0);
*/
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto Manager = TListedActors<ASkylineWhipBirdManager>().Single;

		if (Manager != nullptr)
			Manager.RemoveTarget(this);
	}
};