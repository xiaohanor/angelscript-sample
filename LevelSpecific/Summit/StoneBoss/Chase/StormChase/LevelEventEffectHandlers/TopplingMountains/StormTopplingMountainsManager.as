class AStormTopplingMountainsManager : AHazeActor
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
	void CallTopplingMountains()
	{
		UStormTopplingMountainsEventHandler::Trigger_StartMountainsToppling(this, FStormEventTopplingMountainsParams(ActorLocation));
	}
};