class UForgeLavaCollectorComponent : UActorComponent
{

	UPROPERTY(EditAnywhere)
	TArray<AActor> EntrancePaths;

	UPROPERTY(EditAnywhere)
	bool bFinalPath;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AActor EntrancePath : EntrancePaths)
		{
			UForgeLavaFlowComponent ForgeLavaFlowComponent = UForgeLavaFlowComponent::Get(EntrancePath);	


			ForgeLavaFlowComponent.OnLavaFlowReachedEnd.AddUFunction(this, n"CollectLava");
			//ForgeLavaFlowComponent.OnLavaFlowReachedEnd.AddUFunction(this, n"FailureLava");
			
		}

	
	}
	
	/*UFUNCTION()
	private void FailureLava (AForgeLavaBall ForgeLavaBall)
	{
		Print("ULostThisOneLul");
		ForgeLavaBall.DestroyActor();
		ForgeLavaBall.bHasLost = true;
	}
	*/
	
	UFUNCTION()
	private void CollectLava(AForgeLavaBall ForgeLavaBall)
	{
		Print("THankYouforBEatingTheGame");
		ForgeLavaBall.DestroyActor();
	}

}