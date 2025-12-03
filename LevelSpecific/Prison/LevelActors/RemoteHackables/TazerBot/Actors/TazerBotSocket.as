event void FTazerBotSocketEvent();

UCLASS(Abstract)
class ATazerBotSocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComponent;

	UPROPERTY(DefaultComponent)
	USceneComponent SocketBase;

	UPROPERTY(DefaultComponent, Attach = SocketBase)
	USceneComponent SocketRoot;

	UPROPERTY(DefaultComponent, Attach = SocketRoot)
	UCapsuleComponent SocketTrigger;

	UPROPERTY(DefaultComponent, Attach = SocketRoot)
	USceneComponent BotAttachComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;

	UPROPERTY()
	FTazerBotSocketEvent OnSocketActivated;

	UPROPERTY(EditAnywhere)
	UHazeAudioEvent SocketConnectedEvent;

	bool bBotFullyConnected = false;
	bool bTipConnected = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SocketTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnSocketOverlap");
	}

	UFUNCTION()
	private void OnSocketOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		ATazerBot TazerBot = Cast<ATazerBot>(OtherActor);
		if (TazerBot == nullptr)
			return;

		if (!TazerBot.HackingPlayer.HasControl())
			return;

		Crumb_SocketOverlap(TazerBot);
	}

	UFUNCTION(CrumbFunction)
	void Crumb_SocketOverlap(ATazerBot TazerBot)
	{
		TazerBot.ActivateDelayedDestroy(this);
		OnSocketActivated.Broadcast();

		if(!bTipConnected)
			AudioComponent::PostFireForget(SocketConnectedEvent, FHazeAudioFireForgetEventParams());

		UTazerBotSocketEffectEventHandler::Trigger_BotTipConnected(this);
		bTipConnected = true;
	}

	UFUNCTION()
	void BotFullyConnected()
	{
		if (bBotFullyConnected)
			return;

		bBotFullyConnected = true;
		UTazerBotSocketEffectEventHandler::Trigger_BotFullyConnected(this);
	}
}

class UTazerBotSocketEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void BotTipConnected() {}
	UFUNCTION(BlueprintEvent)
	void BotFullyConnected() {}
}