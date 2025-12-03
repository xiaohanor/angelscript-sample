UCLASS(Abstract)
class APrisonBossBrainHackablePanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PanelRoot;

	UPROPERTY(DefaultComponent, Attach = PanelRoot)
	URemoteHackingResponseComponent HackingResponseComp;

	UPROPERTY()
	FRemoteHackingEvent OnHacked;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HackingResponseComp.OnHackingStarted.AddUFunction(this, n"Hacked");
	}

	UFUNCTION()
	private void Hacked()
	{
		OnHacked.Broadcast();
	}

	UFUNCTION()
	void SetHackingAllowed(bool bAllow)
	{
		if (bAllow)
			HackingResponseComp.SetHackingAllowed(true);
		else
			HackingResponseComp.SetHackingAllowed(false);
	}
}