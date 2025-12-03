class AStoneBeastLavaEnterManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(20));
	default Visual.SpriteName = "S_RadForce";
#endif

	UFUNCTION()
	void CallLavaEnter()
	{
		UStoneBeastLavaEnterEventHandler::Trigger_OnStoneBeastEnter(this, FOnStoneBeastEnterLavaParams(ActorLocation));
	}
};