class ARollingOgreWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WheelRoot;

	UPROPERTY(DefaultComponent, Attach = WheelRoot)
	UDeathTriggerComponent DeathTriggerComp1;
	UPROPERTY(DefaultComponent, Attach = WheelRoot)
	UDeathTriggerComponent DeathTriggerComp2;
	UPROPERTY(DefaultComponent, Attach = WheelRoot)
	UDeathTriggerComponent DeathTriggerComp3;
	UPROPERTY(DefaultComponent, Attach = WheelRoot)
	UDeathTriggerComponent DeathTriggerComp4;
}