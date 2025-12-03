event void FSkylinePowerPlugSocketSignature();

class ASkylinePowerPlugSocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SocketPivot;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipSlingAutoAimComponent AutoAimTarget;

	FSkylinePowerPlugSocketSignature OnForceUnplug;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect WorldForceFeedback;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect ZoeForceFeedBack;

	bool bSocketed = false;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void Activate()
	{
		BP_OnActivate();
		InterfaceComp.TriggerActivate();
		ForceFeedback::PlayWorldForceFeedback(WorldForceFeedback, ActorLocation, false, this, 380, 420, 1, 1, EHazeSelectPlayer::Both);
		ForceFeedback::PlayWorldForceFeedback(ZoeForceFeedBack,  ActorLocation, false, this, 2000, 2420, 1, 1, EHazeSelectPlayer::Zoe);
	}

	void Deactivate()
	{
		ForceFeedback::PlayWorldForceFeedback(WorldForceFeedback, ActorLocation, false, this, 380, 420, 1, 1, EHazeSelectPlayer::Both);
		BP_OnDeactivate();
		InterfaceComp.TriggerDeactivate();
	}

	UFUNCTION()
	void ForceUnplug()
	{
		OnForceUnplug.Broadcast();	
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivate() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivate() {}
};