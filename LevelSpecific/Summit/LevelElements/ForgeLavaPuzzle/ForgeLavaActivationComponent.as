class UForgeLavaActivationComponent : UActorComponent 
{

UPROPERTY(DefaultComponent, RootComponent)
USceneComponent Root;

UPROPERTY(EditAnywhere)
TSubclassOf<AForgeLavaBall> LavaBall;


UFUNCTION()
void StartLava() 
{
	Print("LavaGoesHere");
}	


}
