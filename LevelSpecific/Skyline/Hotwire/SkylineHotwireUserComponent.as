class USkylineHotwireUserComponent : UActorComponent
{
	FVector2D Input;
	bool bIsActivated = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineHotwireTool> MioToolClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineHotwireTool> ZoeToolClass;

	UPROPERTY(EditDefaultsOnly)
	float ToolMovementSpeed = 10.0;

	ASkylineHotwireTool Tool;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	ASkylineHotwireTool SpawnTool(AHazePlayerCharacter User, ASkylineHotwire Hotwire)
	{
		TSubclassOf<ASkylineHotwireTool> ToolClass = (User.IsMio() ? MioToolClass : ZoeToolClass);

		auto SpawnedTool = SpawnActor(ToolClass, bDeferredSpawn = true);
		SpawnedTool.User = User;
		SpawnedTool.Pivot.RelativeLocation = -FVector::ForwardVector * Hotwire.Radius;
		SpawnedTool.AngleSpeed = (ToolMovementSpeed * 360.0) / (Hotwire.Radius * PI * 2.0);
		FinishSpawningActor(SpawnedTool);
		return SpawnedTool;
	}
};