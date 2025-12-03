event void FEventSuccessfulGroundSlam();
event void FEventFailedGroundSlam();

class ATundra_River_SmashStoneWall : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamComponent;

	UPROPERTY()
	FEventSuccessfulGroundSlam SuccessfulGroundSlam;

	UPROPERTY()
	FEventFailedGroundSlam FailedGroundSlam;

	bool bCanBeBroken = false;
	bool bBroken = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundSlamComponent.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
		SetActorControlSide(Game::GetMio());
	}

	UFUNCTION()
	void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType Type, FVector GroundSlamLocation)
	{
		if(HasControl())
		{
			if(!bBroken)
			{
				if(bCanBeBroken)
				{
					CrumbGroundSlamSuccessful();
				}
				else if (!bCanBeBroken)
				{
					CrumbGroundSlamFailed();
				}
			}
		}
	}

	UFUNCTION()
	void SetCanBeBroken(bool CanBeBroken)
	{
		bCanBeBroken = CanBeBroken;
	}

	UFUNCTION(CrumbFunction)
	void CrumbGroundSlamSuccessful()
	{
		bBroken = true;
		SuccessfulGroundSlam.Broadcast();
		UTundra_River_SmashStoneWall_EffectHandler::Trigger_SuccessfulGroundSlam(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbGroundSlamFailed()
	{
		FailedGroundSlam.Broadcast();
		UTundra_River_SmashStoneWall_EffectHandler::Trigger_FailedGroundSlam(this);
	}
}