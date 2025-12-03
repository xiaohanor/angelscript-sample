event void FEventSlam();

class ATundra_River_BreakStalactites : AHazeActor
{
	UPROPERTY()
	FEventSlam SlamRight;

	UPROPERTY()
	FEventSlam SlamLeft;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent TreeComponent;

	bool bTreeInteracting;

	float LastInput = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::GetZoe());
		TreeComponent.OnInteractStart.AddUFunction(this, n"OnInteractStart");
		TreeComponent.OnInteractStop.AddUFunction(this, n"OnInteractStop");
	}

	UFUNCTION()
	void OnInteractStart(bool bForced)
	{
		SetActorTickEnabled(true);
		bTreeInteracting = true;
	}

	UFUNCTION()
	void OnInteractStop(bool bForced)
	{
		//SetActorTickEnabled(false);
		bTreeInteracting = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			if(bTreeInteracting)
			{
				if(Math::Abs(TreeComponent.GetHorizontalAlpha()) > 0.2)
				{
					if((Math::IsNearlyZero(LastInput, SMALL_NUMBER)))
					{
						LastInput = Math::Sign(TreeComponent.GetHorizontalAlpha());
						CrumbTriggerSlam(LastInput > 0);
					}
				}

				else
				{
					LastInput = 0;
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerSlam(bool bRightSlam)
	{
		if(bRightSlam)
		{
			SlamRight.Broadcast();
		}
		else
		{
			SlamLeft.Broadcast();
		}
	}
}