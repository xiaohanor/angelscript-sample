event void FIslandOverseerDeployRollerManagerComponentDeployEvent();

class UIslandOverseerDeployRollerManagerComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	int ShieldActivations;

	UPROPERTY()
	TSubclassOf<AIslandOverseerRoller> RollerClass;

	UIslandOverseerDeployRollerComponent LeftRoller;
	UIslandOverseerDeployRollerComponent RightRoller;
	UIslandOverseerDeployRollerComponent CurrentRoller;

	FIslandOverseerDeployRollerManagerComponentDeployEvent OnDeploy;

	bool bRight;
	bool bHidden;
	private bool bSetup;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetupRollers();
		// HideRollers();
	}

	// UFUNCTION()
	// void HideRollers()
	// {
	// 	if(bHidden)
	// 		return;
	// 	LeftRoller.Roller.AddActorVisualsBlock(this);
	// 	RightRoller.Roller.AddActorVisualsBlock(this);
	// 	bHidden = true;
	// }

	// UFUNCTION()
	// void ShowRollers()
	// {
	// 	if(!bHidden)
	// 		return;
	// 	LeftRoller.Roller.RemoveActorVisualsBlock(this);
	// 	RightRoller.Roller.RemoveActorVisualsBlock(this);
	// 	bHidden = false;
	// }

	void SetupRollers()
	{
		if(bSetup)	
			return;
		bSetup = true;

		TArray<UIslandOverseerDeployRollerComponent> Rollers;
		Owner.GetComponentsByClass(UIslandOverseerDeployRollerComponent, Rollers);

		for(UIslandOverseerDeployRollerComponent Roller : Rollers)
		{
			if(Owner.ActorRightVector.DotProduct(Roller.WorldLocation - Owner.ActorLocation) > 0)
				RightRoller = Roller;
			else
				LeftRoller = Roller;
		}

		LeftRoller.SetupRoller(EIslandForceFieldType::Blue);
		RightRoller.SetupRoller(EIslandForceFieldType::Red);
	}
}