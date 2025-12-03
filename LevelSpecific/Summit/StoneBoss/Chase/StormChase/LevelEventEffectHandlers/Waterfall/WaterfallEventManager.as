class AWaterfallEventManager : AHazeActor
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
	void OnDragonsWaterEnter() 
	{
		UWaterfallEventManagerEffectHandler::Trigger_OnDragonsWaterEnter(this);
	}

	UFUNCTION()
	void OnDragonsWaterExit() 
	{
		UWaterfallEventManagerEffectHandler::Trigger_OnDragonsWaterExit(this);
	}
	
	UFUNCTION()
	void OnStoneBeastWaterExit() 
	{
		UWaterfallEventManagerEffectHandler::Trigger_OnStoneBeastWaterExit(this);
	}
};