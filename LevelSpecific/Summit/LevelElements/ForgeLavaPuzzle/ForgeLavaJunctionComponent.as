class UForgeLavaJunctionComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TArray<AActor> PossiblePaths;

	UPROPERTY(EditAnywhere)
	TArray<AActor> EntrancePaths;

	UPROPERTY(EditAnywhere)
	int SelectedPath = 0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AActor EntrancePath : EntrancePaths)
		{
			UForgeLavaFlowComponent ForgeLavaFlowComponent = UForgeLavaFlowComponent::Get(EntrancePath);
			ForgeLavaFlowComponent.OnLavaFlowReachedEnd.AddUFunction(this, n"PathSelection");
		}

	
	}

	
	UFUNCTION()
	private void PathSelection(AForgeLavaBall ForgeLavaBall)
	{
		ForgeLavaBall.FollowSpline(PossiblePaths[SelectedPath]);
	}
	

	UFUNCTION()
	void NextPath()
	{
		SelectedPath = Math::WrapIndex(SelectedPath + 1, 0, PossiblePaths.Num());
		Print("SelectedPath" + SelectedPath);
	}
}