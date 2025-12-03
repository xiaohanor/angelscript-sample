UCLASS(Abstract)
class APigWorldGrillVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent OverlapComp;

	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlapComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerBeginOverlap");
		OverlapComp.OnPlayerLeave.AddUFunction(this, n"OnPlayerEndOverlap");
	}

	UFUNCTION()
	private void OnPlayerBeginOverlap(AHazePlayerCharacter Player)
	{
		if(bIsActive)
		{
			Player.GetComponent(UPlayerPigSausageComponent).StartGrill();
			FPigWorldGrillParams Params;
			Params.Player = Player;
			UPigWorldGrillEventHandler::Trigger_GrillingEntered(this,Params);
		}
	}

	UFUNCTION()
	private void OnPlayerEndOverlap(AHazePlayerCharacter Player)
	{
		if(bIsActive)
			Player.GetComponent(UPlayerPigSausageComponent).StopGrill();
	}

	UFUNCTION(BlueprintCallable)
	void Activate(AHazePlayerCharacter Player)
	{
		if(OverlapComp.IsPlayerInTrigger(Player.OtherPlayer))
			Player.OtherPlayer.GetComponent(UPlayerPigSausageComponent).StartGrill();

		FPigWorldGrillParams Params;
		Params.Player = Player;
		UPigWorldGrillEventHandler::Trigger_GrillingEntered(this,Params);
		
		bIsActive = true;
	}
	
};