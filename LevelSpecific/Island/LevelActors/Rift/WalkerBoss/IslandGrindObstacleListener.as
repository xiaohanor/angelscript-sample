event void FAIslandGrindObstacleListenerSignature();
event void FIslandGrindObstacleListenerUpdateDisplaySignature(float PercentageAlpha);

class AIslandGrindObstacleListener : AHazeActor
{
	UPROPERTY()
	FAIslandGrindObstacleListenerSignature OnCompleted;
	
	UPROPERTY()
	FAIslandGrindObstacleListenerSignature OnReset;

	UPROPERTY()
	FIslandGrindObstacleListenerUpdateDisplaySignature OnUpdateDisplay;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AIslandWalkerGrindObstacle> Children;
	bool bBeingEdited = false;

	bool bFinished;
	int ChildCount;
	int ChildrenActivated;

	UPROPERTY()
	float CurrentPercentage;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChildCount = Children.Num();
		for (auto Child : Children)
		{
			Child.ListenerRef = this;
		}

		OnUpdateDisplay.Broadcast(1.0);
	}

	UFUNCTION()
	void CheckChildren()
	{
		if(bFinished)
			return;

		bool bShouldFinish = false;
		ChildrenActivated = 0;
		for (auto Child : Children)
		{
			if(Child.bIsDestroyed)
			{
				bShouldFinish = true;
				ChildrenActivated++;
			}
			else
			{
				bShouldFinish = false;
			}
		}
		for (auto Child : Children)
		{
			if(!Child.bIsDestroyed)
			{
				bShouldFinish = false;
			}
		}

		float Percentage = float(ChildrenActivated) / float(ChildCount);
		Percentage = 1.0 - Percentage;
		CurrentPercentage = Percentage;
		OnUpdateDisplay.Broadcast(Percentage);

		if (!bShouldFinish)
			return;

		// Call this on both sides so that if one side has finished the puzzle it is also finished on the other side.
		CrumbFinish();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFinish()
	{
		// Since this might get called twice if both the remote side and control side thinks it is finished so return in that case
		if(bFinished)
			return;

		bFinished = true;
		UIslandGrindObstacleListenerEffectHandler::Trigger_OnListenerFinished(this);
		
		OnCompleted.Broadcast();

		if (CameraShake != nullptr) {
			Game::GetMio().PlayCameraShake(CameraShake, this, 1.0);
			Game::GetZoe().PlayCameraShake(CameraShake, this, 1.0);
		}
	}

	UFUNCTION()
	void RespawnLocks()
	{
		if(!bFinished)
			return;

		bFinished = false;
		ChildrenActivated = 0;

		for (auto Child : Children)
		{
			Child.Respawn();
		}

		CurrentPercentage = 1;
		OnUpdateDisplay.Broadcast(1.0);

		UIslandGrindObstacleListenerEffectHandler::Trigger_OnPanelsReset(this);
		OnReset.Broadcast();
	}

	UFUNCTION()
	void ForceActivateLights()
	{
		for (auto Child : Children)
		{
			if (Child.ActivatorRef != nullptr)
				Child.ActivatorRef.ObstacleCompleted();
		}
	}

	UFUNCTION()
	void ForceFinishPuzzle()
	{
		for (auto Child : Children)
		{
			Child.bIsDestroyed = true;
		}
		CheckChildren();
	}
}

UCLASS(Abstract)
class UIslandGrindObstacleListenerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnListenerFinished() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPanelsReset() {}
}