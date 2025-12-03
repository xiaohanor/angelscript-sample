event void FASummitTopDownTailActivatorListenerSignature();

class ASummitTopDownTailActivatorListener : AHazeActor
{

	UPROPERTY()
	FASummitTopDownTailActivatorListenerSignature OnFinished;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitTopDownTailActivator> Children;
	bool bBeingEdited = false;

	UPROPERTY()
	bool bFinished;
	int ChildCount;
	int ChildrenActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChildCount = Children.Num();
		for (auto Child : Children)
		{
			Child.Parent = this;
			
		}
	}

	UFUNCTION()
	void CheckChildren()
	{
		
		for (auto Child : Children)
		{
			if(Child.bIsActivated)
			{
				bFinished = true;
				ChildrenActivated++;
			}
			if(Child.bIsActivated == false)
			{
				bFinished = false;
			}
		}
		for (auto Child : Children)
		{
			if(Child.bIsActivated == false)
			{
				bFinished = false;
			}
		}

		if(!bFinished)
			return;

		if(bFinished) 
		{
			for (auto Child : Children)
			{
				Child.DisableTailActivator();
			}
			OnFinished.Broadcast();
		}
	}

	UFUNCTION()
	void ForceFinishPuzzle()
	{
		for (auto Child : Children)
		{
			Child.bIsActivated = true;
		}
		CheckChildren();
	}

}