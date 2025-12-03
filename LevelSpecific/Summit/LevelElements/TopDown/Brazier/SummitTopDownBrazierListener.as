event void FASummitTopDownBrazierListenerSignature();

class ASummitTopDownBrazierListener : AHazeActor
{

	UPROPERTY()
	FASummitTopDownBrazierListenerSignature OnFinished;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitTopDownBrazier> Children;
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
		if(!HasControl())
			return;

		for (auto Child : Children)
		{
			if(Child.bActivated)
			{
				bFinished = true;
				ChildrenActivated++;
			}
			if(Child.bActivated == false)
			{
				bFinished = false;
			}
		}
		for (auto Child : Children)
		{
			if(Child.bActivated == false)
			{
				bFinished = false;
			}
		}

		if(!bFinished)
			return;

		if(bFinished) 
		{
			CrumbFinishPuzzle();
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbFinishPuzzle()
	{
		for (auto Child : Children)
		{
			Child.bCompleted = true;
			Child.BP_OnFinished();
		}
		OnFinished.Broadcast();
	}

	UFUNCTION()
	void ForceFinishPuzzle()
	{
		for (auto Child : Children)
		{
			Child.bActivated = true;
		}
		CheckChildren();
	}

	UFUNCTION(BlueprintPure)
	float GetCompletionAlpha()
	{
		int NumActivated = 0;
		for(auto Child : Children)
		{
			if(Child.bActivated)
				++NumActivated;
		}

		return float(NumActivated) / Children.Num();
	}

}